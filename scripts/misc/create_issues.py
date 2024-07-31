import json
import subprocess
import sys
import argparse

def create_issue(title, body, labels):
    cmd = [
        "gh", "issue", "create",
        "--title", title,
        "--body", body,
        "--label", ",".join(labels)
    ]
    
    try:
        subprocess.run(cmd, check=True)
        print(f"Successfully created issue: {title}")
    except subprocess.CalledProcessError as e:
        print(f"Error creating issue: {title}")
        print(f"Error message: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Create GitHub issues from a JSON file.")
    parser.add_argument("json_file", help="Path to the JSON file containing issue data")
    args = parser.parse_args()

    try:
        with open(args.json_file, "r") as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: File '{args.json_file}' not found.")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: '{args.json_file}' is not a valid JSON file.")
        sys.exit(1)

    if "issues" not in data:
        print("Error: The JSON file does not contain an 'issues' key.")
        sys.exit(1)

    for issue in data["issues"]:
        create_issue(issue["title"], issue["body"], issue["labels"])

if __name__ == "__main__":
    main()