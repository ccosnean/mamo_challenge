# showcase

The hosted demo. Runs `payments_app` inside an iPhone frame, wired through
`AppConfig` to:

- **Bank:** `mock_bank`, answering the app's HTTP calls. Send requests, top up,
  go offline, add latency, expire the session, reset.
- **Biometrics:** a simulated Face ID sensor. Choose whether scans pass or
  fail; the scan plays at the Dynamic Island.
- **Console:** the app's log output, masked as in production.

```sh
fvm flutter run -d chrome        # from this folder
fvm dart run melos run build:showcase   # release build, from the repo root
```
