%builtins output range_check poseidon

from starkware.cairo.common.cairo_builtins import PoseidonBuiltin

// Simple aggregation program that concatenates task outputs. Used for tests.
// Note that it is not sound (becuase the concatenation function below does not verify that the task
// outputs given by the hint agree with the task outputs in the aggregator input section).
//
// Hint arguments:
// program_input - List of task outputs.
func main{output_ptr: felt*, range_check_ptr, poseidon_ptr: PoseidonBuiltin*}() {
    alloc_locals;

    // Parse the tasks from the program input, and output them in the format of the bootloader
    // output. We also refer to the output of this function as the "aggregator input".
    let n_tasks = parse_tasks();

    // Save the start of the aggregated output.
    local output_start: felt* = output_ptr;

    // Output the concatenated task outputs.
    output_concatenated_output(n_tasks=n_tasks);

    %{
        # Create fact topology, splitting to pages of size 10.
        output_length = ids.output_ptr - ids.output_start
        page_size = 10
        next_page_start = min(ids.output_start + page_size, ids.output_ptr)
        next_page_id = 1
        while next_page_start < ids.output_ptr:
            output_builtin.add_page(
                page_id=next_page_id,
                page_start=next_page_start,
                page_size=min(ids.output_ptr - next_page_start, page_size),
            )
            next_page_start += page_size
            next_page_id += 1
        if next_page_id == 1:
            # Single page. Use trivial fact topology.
            output_builtin.add_attribute('gps_fact_topology', [
                1,
                0,
            ])
        else:
            output_builtin.add_attribute('gps_fact_topology', [
                next_page_id,
                next_page_id - 1,
                0,
                2,
            ])
    %}
    return ();
}

// Outputs the task outputs, without the output sizes. Recall that the purpose of the concat
// aggregator is to concatenate the task outputs. Another aggregator may choose to parse the outputs
// and aggregate them differently.
func output_concatenated_output{output_ptr: felt*}(n_tasks: felt) {
    alloc_locals;
    if (n_tasks == 0) {
        return ();
    }

    local output_size: felt;

    %{
        task_index = len(tasks_outputs) - ids.n_tasks
        segments.load_data(ptr=ids.output_ptr, data=tasks_outputs[task_index])
        ids.output_size = len(tasks_outputs[task_index])
    %}

    let output_ptr = output_ptr + output_size;

    return output_concatenated_output(n_tasks=n_tasks - 1);
}

// Parses the task outputs from the program input. Writes their outputs to the output_ptr, in the
// format of the bootloader output.
// Returns the number of tasks.
// The allowed program hash for the tasks.
// This is used for verifying that the tasks have the correct program hash. If this was given
// instead in a hint, and not as a constant in the cairo code, the aggregator would not be sound, as
// the tasks could be replaced with other arbitrary tasks.
const TASK_PROGRAM_HASH = 0;
func parse_tasks{output_ptr: felt*}() -> felt {
    alloc_locals;
    local n_tasks: felt;
    %{
        # Read the tasks outputs from the program input.
        tasks_outputs: List[List[int]] = program_input["tasks_outputs"]
        assert len(tasks_outputs) > 0, "No tasks found!"
        ids.n_tasks = len(tasks_outputs)
    %}
    assert [output_ptr] = n_tasks;
    let output_ptr = output_ptr + 1;
    // Output the task outputs as they are, with the program hash and the size of the output.
    output_tasks(n_tasks=n_tasks);
    return n_tasks;
}

// Outputs the task outputs, each with the program hash and the size of the output (to match the
// bootloader output format).
func output_tasks{output_ptr: felt*}(n_tasks: felt) {
    if (n_tasks == 0) {
        return ();
    }
    // Output the length of the task output (plus 2, accouting for the program hash and the task
    // output size), and the program hash.
    let output_size = output_ptr[0];
    assert output_ptr[1] = TASK_PROGRAM_HASH;
    let output_ptr = output_ptr + 2;
    %{
        task_index = len(tasks_outputs) - ids.n_tasks
        segments.load_data(ptr=ids.output_ptr, data=tasks_outputs[task_index])
        ids.output_size = len(tasks_outputs[task_index]) + 2
    %}
    let output_ptr = output_ptr + output_size - 2;
    return output_tasks(n_tasks=n_tasks - 1);
}
