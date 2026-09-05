# Commerce app

Flutter storefront translated from the pinned Medusa DTC Starter source into
Dust routes, state, HTTP clients, and shared Dart models.

Run the seeded API from the repository root, then start the web storefront:

```bash
flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 3000 \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

The UI is a source-guided reimplementation. It does not bundle the Medusa
React application or depend on the Medusa runtime.
