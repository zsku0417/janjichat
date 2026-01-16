# How to use ngrok with Laragon (fyp.test)

Since you are using **Laragon** with a custom domain (`fyp.test`), you cannot just run `ngrok http 80`. You need to tell ngrok to "rewrite" the host header so Laragon knows which site you are trying to access.

## The Command

Run this in your terminal:

```powershell
ngrok http janjichat.test:80 --host-header=rewrite
```

### Why `--host-header=rewrite`?
- Unlike `php artisan serve` (which listens on `127.0.0.1:8000`), Laragon uses Nginx/Apache virtual hosts.
- It looks at the "Host" header to decide whether to show you `fyp.test` or `another-app.test`.
- By default, ngrok sends the host `blabla.ngrok.io`. Laragon doesn't recognize that.
- Adding `--host-header=rewrite` tells ngrok to send `Host: fyp.test` to your local server, making it work perfectly.

## Summary

1. **Stop** any existing ngrok session (`Ctrl+C`).
2. **Run**: `ngrok http fyp.test:80 --host-header=rewrite`
3. **Copy** the new HTTPS URL (e.g., `https://your-new-url.ngrok-free.dev`).
4. **Update** your webhook URL in the Meta Dashboard.

/api/webhook/whatsapp


ngrok http janjichat.test:80 --host-header=rewrite
php artisan reverb:start





Admin
-Auto Remind Message
-Manage Welcome message


User
-To receive follow ups in the form of reminders, thank you notes or follow ups basing on the 
activity.





php artisan config:clear; php artisan cache:clear; php artisan route:clear; php artisan view:clear
https://japingly-isodiametric-omega.ngrok-free.dev/api/webhook/whatsapp



php artisan orders:send-reminders
php artisan queue:work --once