To send a message via API, use:

curl -X POST "https://graph.facebook.com/v18.0/897500416781495/messages" \
-H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "messaging_product": "whatsapp",
  "to": "60108685352",
  "type": "text",
  "text": {
    "body": "Hello from my real number!"
  }
}









Subscribe via API:
curl -X POST "https://graph.facebook.com/v18.0/1231142412191077/subscribed_apps" \
-H "Authorization: Bearer YOUR_PERMANENT_ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "subscribed_fields": "messages"
}
