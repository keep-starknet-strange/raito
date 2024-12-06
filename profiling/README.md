## Profiling
 ```
 snforge test --build-profile -- --show-details
 ```

## Pprof
```
go tool pprof -http=":8000" profile/shinigami_profiling_tests\:\:test\:\:test_24839_full.pb.gz
```

