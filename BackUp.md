# WhatsApp AI Chatbot with Knowledge Base & Booking System

A web-based system that integrates AI with WhatsApp to provide automated customer service, intelligent Q&A from uploaded documents, and booking management.

---

## 🎯 What This System Does

| Feature | Description |
|---------|-------------|
| **Knowledge Base** | Admin uploads documents (PDF, DOCX, TXT) → AI learns from them |
| **WhatsApp Chatbot** | Auto-replies to customers using knowledge base (24/7) |
| **Smart Escalation** | If AI cannot answer → marks conversation for admin reply |
| **Booking Management** | Customers can create/update/cancel bookings via chat |

---

## 🛠 Technology Stack

| Component | Technology |
|-----------|------------|
| Backend | Laravel (PHP) |
| Frontend | Vue.js |
| Database | PostgreSQL + pgvector |
| AI Model | OpenAI GPT-4o-mini |
| Messaging | WhatsApp Business Cloud API (Meta) |
| Development Environment | Laragon + Docker (PostgreSQL + pgvector) |

---

## 📐 System Architecture

```
┌──────────────────────────────────────────────────────────┐
│                 ADMIN PANEL (Vue.js)                     │
│  • Upload documents    • Manage bookings                 │
│  • View conversations  • Chat with customers             │
│  • Configure AI tone   • Set restaurant settings         │
└────────────────────────────┬─────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────┐
│                  LARAVEL BACKEND                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │
│  │  Document   │  │   Booking   │  │    WhatsApp     │   │
│  │ Processing  │  │  Management │  │     Webhook     │   │
│  └──────┬──────┘  └──────┬──────┘  └────────┬────────┘   │
│         └────────────────┼──────────────────┘            │
│                          ▼                               │
│         ┌────────────────────────────────────┐           │
│         │     AI SERVICE (RAG System)        │           │
│         │  • Vector search (pgvector)        │           │
│         │  • OpenAI GPT-4o-mini              │           │
│         │  • Intent detection                │           │
│         │  • Conversation memory             │           │
│         │  • Confidence evaluation           │           │
│         └────────────────────────────────────┘           │
└──────────────────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────┐
│                  EXTERNAL SERVICES                       │
│  • WhatsApp Business Cloud API    • OpenAI API           │
└──────────────────────────────────────────────────────────┘
```

---

## 🔄 System Flow Explanation

### How Document Processing Works

When an admin uploads a document to the system, the backend first extracts all the text content from the file regardless of its format (PDF, DOCX, or TXT). The extracted text is then split into smaller chunks to make searching more efficient. Each chunk is converted into a vector embedding using OpenAI's embedding model, and these embeddings are stored in the PostgreSQL database with the pgvector extension. This allows the system to perform semantic search, meaning it can find relevant information even if the customer's question doesn't use the exact same words as the document.

### How Customer Conversation Works

When a customer sends a message to the business WhatsApp number, the message is received by the Laravel backend through a webhook. The system first checks the conversation status to determine if it should be handled by AI or if it's waiting for admin reply. If the conversation is set to AI mode (which is the default), the system proceeds to process the message.

The AI analyzes the message to detect the customer's intent, which could be a general question, a booking request, or a casual greeting. The AI also has access to the full conversation history, so it remembers what has been discussed previously and can maintain context throughout the conversation. The AI automatically detects and responds in the same language that the customer is using.

For general questions, the system searches the knowledge base using vector similarity search to find the most relevant information. If relevant content is found, the AI generates a natural response based on that information and sends it back to the customer via WhatsApp.

If the AI cannot find relevant information in the knowledge base or is unsure how to respond, the system does NOT send any automated reply to the customer. Instead, it marks the conversation as "Needs Admin Reply" and shows a notification in the admin dashboard in real-time. The system also records the reason why the AI couldn't answer, displayed to the admin in a few sentences. The admin can then view the conversation in the admin panel and manually reply to the customer directly from the web interface. After the admin has addressed the issue, they can toggle the conversation back to AI mode, and the system will resume auto-replying to that customer.

If a customer sends non-text messages such as images, voice messages, videos, or documents, the system will not auto-reply. Instead, it marks the conversation for admin to handle manually.

### How AI Decides It Cannot Answer

The system uses two layers to determine if the AI can confidently answer a question:

**Layer 1 - Vector Search Score**: When searching the knowledge base, the system checks the similarity score of the results. If the highest score is below 0.7, it means no relevant document was found, and the AI should not attempt to answer from the knowledge base.

**Layer 2 - AI Self-Evaluation**: Even if relevant documents are found, the AI evaluates its own confidence in the answer. If the information is vague, conflicting, or the AI is unsure, it will decline to answer automatically. This prevents the AI from giving potentially incorrect information to customers.

In both cases, the conversation is marked for admin reply, and the AI does not send any response to the customer.

### How Booking Flow Works

When the AI detects that a customer wants to make a booking, it engages in a conversational flow to collect the necessary information. The AI will ask for the customer's name, preferred date, preferred time, number of guests, and any special requests. The AI collects this information naturally through conversation, confirming each detail as it goes.

Once all required information is gathered, the AI checks the availability in the booking system based on the restaurant's table configuration and operating hours. If the requested slot is available, it creates the booking and sends a customizable confirmation message to the customer. If the slot is not available, the AI informs the customer that no tables are available and suggests alternative dates or times.

Customers can also inquire about their existing bookings, request to modify the date or time, or cancel their reservations, all through natural conversation with the AI.

The system automatically sends a reminder message to customers before their booking. By default, this is sent 24 hours before the booking time, but the admin can adjust this duration. The reminder message content is also customizable by the admin.

### Conversation Mode Control

Every conversation has a mode flag that determines whether it should be handled by AI or by admin. When a new customer initiates a conversation, this flag is set to "AI Mode" by default, meaning the system will automatically respond to their messages 24/7.

If at any point the AI cannot confidently answer a question, it automatically switches the conversation to "Admin Mode" and shows a notification in the admin dashboard. While in Admin Mode, the system will not send any automated replies, allowing the admin to handle the conversation personally through the web panel.

The admin has full control through a toggle switch in the admin panel. They can manually switch any conversation between AI Mode and Admin Mode at any time. This is useful when an admin wants to personally handle a VIP customer or when they've resolved an issue and want to hand the conversation back to the AI.

---

## 🤖 AI Configuration

### Customizable Settings

| Setting | Description | Default |
|---------|-------------|---------|
| **Tone/Personality** | Admin can customize how the AI speaks (formal, friendly, casual, etc.) | Friendly and professional |
| **Language** | AI automatically detects and responds in customer's language | Auto-detect |
| **Confidence Threshold** | Vector search score threshold for finding relevant answers | 0.7 |

### AI Behavior Summary

- Responds 24/7 to customer messages
- Remembers full conversation history for context
- Auto-detects customer's language
- Shows admin why it couldn't answer when escalating
- Never replies when unsure (marks for admin instead)

---

## 📁 Knowledge Base

### Features

| Feature | Description |
|---------|-------------|
| **Supported Formats** | PDF, DOCX, TXT |
| **File Size Limit** | No limit |
| **Edit Documents** | Must delete and re-upload |
| **Conflicting Information** | If AI detects conflicting info between documents, it marks the conversation for admin |

### How It Works

1. Admin uploads document via admin panel
2. System extracts text content
3. Text is split into smaller chunks
4. Each chunk is converted to vector embedding
5. Embeddings stored in PostgreSQL with pgvector
6. When customer asks a question, system searches for similar content
7. AI generates response based on found content

---

## 🍽 Booking System

### Current Implementation: Restaurant Table Booking

The initial version of the booking system is designed for restaurant table reservations. This serves as the foundation for future expansion to other booking types.

### Restaurant Configuration

| Setting | Description |
|---------|-------------|
| **Tables** | Each table configured individually with a name and maximum capacity (e.g., "Table 1" = 4 pax, "VIP Room" = 10 pax) |
| **Operating Hours** | Admin sets opening and closing time (e.g., 10:00 AM - 10:00 PM) |
| **Time Slot Duration** | Fixed 2 hours per booking |

### Booking Information Required

| Field | Required | Description |
|-------|----------|-------------|
| Name | Yes | Customer's name |
| Phone | Yes | Customer's WhatsApp number (auto-captured) |
| Date | Yes | Booking date |
| Time | Yes | Booking time |
| Pax | Yes | Number of guests |
| Special Request | No | Any special notes or requests |

### Booking Rules

| Rule | Behavior |
|------|----------|
| **Same Day Booking** | Allowed, as long as tables are available |
| **Advance Booking** | No limit on how far in advance |
| **Double Booking Prevention** | System automatically prevents overbooking |
| **No Availability** | AI informs customer and suggests alternative date/time |

### Booking Messages

| Message Type | Customizable | Default Template |
|--------------|--------------|------------------|
| **Confirmation** | Yes | "Your booking is confirmed! Date: XX, Time: XX, Pax: XX" |
| **Reminder** | Yes | Sent 24 hours before (duration adjustable by admin) |

### What Customers Can Do via WhatsApp

- Book a table by specifying date, time, and number of guests
- Add special requests or notes
- Check their existing booking status
- Modify their booking (change date, time, or party size)
- Cancel their booking

### What Admins Can Do via Admin Panel

- View all bookings in a calendar or list view
- Manually create bookings for walk-in or phone customers
- Modify or cancel any booking
- Configure tables and their capacities
- Set operating hours
- Customize confirmation and reminder messages
- Adjust reminder timing

### Future Expansion

The booking system is designed with extensibility in mind. The database schema uses a flexible structure that can accommodate different booking types in the future. Potential expansions include:

- **Salon/Spa Appointments**: Adding service type selection and staff assignment
- **Hotel Room Reservations**: Adding room types, check-in/check-out dates
- **Clinic Appointments**: Adding doctor selection and appointment categories
- **Event Bookings**: Adding venue selection and event packages

Each new booking type will share the core booking logic while having its own specific fields and validation rules.

---

## 💬 Conversation Handling

### AI Memory

The AI maintains context throughout each conversation by storing and retrieving the full message history. Conversation history is stored forever. This means customers don't need to repeat information they've already provided. For example, if a customer mentioned their name earlier in the conversation, the AI will remember it when creating a booking later.

### Conversation Modes

| Mode | Behavior | When It's Used |
|------|----------|----------------|
| **AI Mode** (Default) | System auto-replies using AI | New conversations, after admin toggles back |
| **Admin Mode** | No auto-reply, waits for admin | When AI can't answer, non-text messages received, or admin manually switches |

### Mode Switching Flow

```
New Conversation Started
         │
         ▼
    [AI Mode] ←──────────────────────────────┐
         │                                   │
         ▼                                   │
  Customer Sends Message                     │
         │                                   │
         ├── Non-text message?               │
         │        │                          │
         │       Yes → Switch to [Admin Mode]│
         │        │                          │
         No       ▼                          │
         │    Notify Admin (no reply sent)   │
         │                                   │
         ▼                                   │
   AI Can Answer?                            │
         │                                   │
    Yes  │  No                               │
         │   │                               │
         ▼   ▼                               │
   Reply    Switch to [Admin Mode]           │
         │   │                               │
         │   ▼                               │
         │  Notify Admin + Show Reason       │
         │   │                               │
         │   ▼                               │
         │  Admin Replies from Web Panel     │
         │   │                               │
         │   ▼                               │
         │  Admin Toggles Switch ────────────┘
         │
         ▼
   Continue Conversation
```

### Admin Notification

When the AI cannot answer a question, the admin receives a real-time notification in the dashboard. The notification includes:
- Customer's phone number
- The message that couldn't be answered
- Reason why AI couldn't answer (in a few sentences)
- Link to open the conversation

---

## 👨‍💼 Admin Panel

### Authentication

| Setting | Value |
|---------|-------|
| Multiple Admins | Yes |
| Permission Levels | All admins have same permissions |
| Account Creation | Manually seeded in database |

### Dashboard Statistics

The admin dashboard displays:
- Total conversations
- Total bookings
- Unanswered questions (conversations needing admin reply)
- Upcoming bookings

### Features

| Feature | Description |
|---------|-------------|
| **Chat with Customers** | Admin can reply to customers directly from the web panel → message sent to customer's WhatsApp |
| **Conversation Management** | View all conversations, see history, toggle AI/Admin mode |
| **Knowledge Base Management** | Upload, view, and delete documents |
| **Booking Management** | View, create, modify, cancel bookings |
| **Restaurant Settings** | Configure tables, operating hours |
| **Message Templates** | Customize confirmation and reminder messages |
| **AI Settings** | Configure AI tone and personality |

---

---

## ⚙️ Technical Setup

For below Prerequisites, i have install all

### Prerequisites

| Requirement | Description |
|-------------|-------------|
| **Laragon** | Local development environment (Apache, PHP, Node.js) |
| **Docker Desktop** | Required for PostgreSQL + pgvector only |
| **Composer** | PHP dependency manager (included in Laragon) |
| **Git** | Version control |

### Step 1: Install Laragon and Docker Desktop

**Laragon:**
1. Download from [laragon.org](https://laragon.org/download/)
2. Install and run Laragon
3. Laragon includes PHP, Apache, Node.js, Composer

**Docker Desktop:**
1. Download from [docker.com](https://www.docker.com/products/docker-desktop)
2. Install and make sure Docker is running
3. Docker is only needed for PostgreSQL + pgvector

### Step 2: Create Laravel Project in Laragon

```bash
# Option A: Via Laragon Menu
# Right-click Laragon > Quick app > Laravel

# Option B: Via Terminal
cd C:\laragon\www
composer create-project laravel/laravel whatsapp-chatbot
```

Your project will be accessible at: `http://whatsapp-chatbot.test`

### Step 3: Configure Environment Variables

Edit the `.env` file:

```env
# Application
APP_NAME="WhatsApp AI Chatbot"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://whatsapp-chatbot.test

# Database (Docker PostgreSQL)
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=whatsapp_chatbot
DB_USERNAME=postgres
DB_PASSWORD=secret

# OpenAI
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# WhatsApp Business API (Meta)
WHATSAPP_PHONE_NUMBER_ID=87493358710768
WHATSAPP_ACCESS_TOKEN=EAAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
WHATSAPP_VERIFY_TOKEN=my_fyp_chatbot_2024

# AI Configuration
AI_CONFIDENCE_THRESHOLD=0.7
```

### Step 4: Start Docker (PostgreSQL Only)

Create `docker-compose.yml` in your project root:

```yaml
version: '3.8'

services:
  pgsql:
    image: pgvector/pgvector:pg16
    container_name: whatsapp_chatbot_db
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: whatsapp_chatbot
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

Start PostgreSQL container:

```bash
docker-compose up -d
```

### Step 5: Install pgvector Extension

```bash
# Access PostgreSQL container and enable pgvector
docker exec -it whatsapp_chatbot_db psql -U postgres -d whatsapp_chatbot -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Verify installation
docker exec -it whatsapp_chatbot_db psql -U postgres -d whatsapp_chatbot -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
```

### Step 6: Run Migrations and Seeders

```bash
# Run database migrations
php artisan migrate

# Seed admin accounts
php artisan db:seed --class=AdminSeeder
```

### Step 7: Setup Frontend (Vue.js)

```bash
# Install Node dependencies
npm install

# Run development server
npm run dev
```

### Step 8: Setup WhatsApp Webhook (ngrok)

```bash
I have download ngrok from microsoft store, later need guide me how to set up

I also have login for ngrok, and i have my Authtoken
# Expose local server to internet (Laragon uses port 80)
ngrok http 80

# Your webhook URL will be: https://xxxxx.ngrok.io/api/webhook/whatsapp
```

---


## 🔑 API Credentials Setup
For below API Credentials, i have sign up and set up all

i have the Key already
OPENAI_API_KEY=sk-proj-1hdwdhidjwmfsfjiwer2fwfwfwfw

WHATSAPP_PHONE_NUMBER_ID=87493358710768
WHATSAPP_ACCESS_TOKEN=wfweknfsovdpgwfmsklvmdklnkedgw
WHATSAPP_VERIFY_TOKEN=my_fyp_chatbot_2024

### OpenAI API Key

1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign up or log in
3. Go to **Settings** → **Billing** → Add payment method
4. Go to **API Keys** → Click **"Create new secret key"**
5. Name it: `whatsapp-chatbot`
6. Copy the key immediately (you won't see it again!)

```env
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### WhatsApp Business API (Meta)

#### Step 1: Create Meta Developer Account

1. Go to [developers.facebook.com](https://developers.facebook.com)
2. Click **"Get Started"** and create account
3. Verify your account

#### Step 2: Create WhatsApp Business App

1. Go to [developers.facebook.com/apps](https://developers.facebook.com/apps)
2. Click **"Create App"**
3. Select **"Other"** → **"Business"** → **"Next"**
4. Fill in app name (e.g., `FYP`) and create

#### Step 3: Add WhatsApp to Your App

1. In your app dashboard, go to **"Use cases"**
2. Find **"Connect with customers through WhatsApp"**
3. Click **"Customize"**

#### Step 4: Get Your Credentials

In the WhatsApp API Setup page:

| Credential | Where to Find |
|------------|---------------|
| **Phone Number ID** | Shown on API Setup page (e.g., `87493358710768`) |
| **Test Number** | Meta provides test number (e.g., `+1 555 092 6895`) |
| **Your Phone** | Add your personal number as test recipient |

#### Step 5: Create Permanent Access Token (Important!)

The temporary token expires in 60 minutes. Create a permanent token:

1. Go to [business.facebook.com/settings](https://business.facebook.com/settings)
2. In left sidebar: **Users** → **System users**
3. Click **"Add"** button
4. Fill in:
   - **Name:** `fyp-admin`
   - **Role:** `Admin`
5. Click **"Create system user"**
6. Click on **"fyp-admin"** → Click **"Add assets"**
7. Select **"Apps"** → Check your app **"FYP"** → Enable **"Full control"**
8. Click **"Save changes"**
9. Click **"Generate new token"**
10. Select app: **"FYP"**
11. Select permissions:
    - ✅ `whatsapp_business_messaging`
    - ✅ `whatsapp_business_management`
12. Click **"Generate token"**
13. **Copy the token** - this is your permanent token!

```env
WHATSAPP_PHONE_NUMBER_ID=87493358710768
WHATSAPP_ACCESS_TOKEN=EAAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
WHATSAPP_VERIFY_TOKEN=my_fyp_chatbot_2024
```

> **Note:** `WHATSAPP_VERIFY_TOKEN` is any string you create yourself. It's used to verify your webhook.

#### Step 6: Add Test Recipient

1. On the API Setup page, under **"To"** field
2. Click **"Manage phone number list"**
3. Add your personal WhatsApp number
4. Verify with the code sent to your phone

#### Step 7: Test Send Message

1. On API Setup page, select **"Plain text"** message type
2. Click **"Send message"**
3. Check your WhatsApp - you should receive a test message!

---

## 📱 WhatsApp Webhook Configuration

### Step 1: Start ngrok

```bash
ngrok http 80
```

Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`)

### Step 2: Configure Webhook in Meta

1. Go to your app in Meta Developer Dashboard
2. Go to **WhatsApp** → **Configuration**
3. Under **Webhook**, click **"Edit"**
4. Enter:
   - **Callback URL:** `https://your-ngrok-url/api/webhook/whatsapp`
   - **Verify token:** `my_fyp_chatbot_2024` (must match your .env)
5. Click **"Verify and save"**
6. Under **Webhook fields**, subscribe to:
   - ✅ `messages`
   - ✅ `message_status`

---

## 🚀 Commands Reference

### Docker Commands (PostgreSQL)

| Command | Description |
|---------|-------------|
| `docker-compose up -d` | Start PostgreSQL container |
| `docker-compose down` | Stop PostgreSQL container |
| `docker-compose logs` | View container logs |
| `docker exec -it whatsapp_chatbot_db psql -U postgres` | Access PostgreSQL CLI |

### Laravel Commands (Laragon Terminal)

| Command | Description |
|---------|-------------|
| `php artisan migrate` | Run database migrations |
| `php artisan db:seed` | Run database seeders |
| `php artisan serve` | Start Laravel server (optional, Laragon handles this) |
| `php artisan tinker` | Access Laravel REPL |

### Frontend Commands

| Command | Description |
|---------|-------------|
| `npm install` | Install dependencies |
| `npm run dev` | Start Vite dev server |
| `npm run build` | Build for production |

---

## 🧪 Testing the System

### 1. Test Database Connection

```bash
php artisan tinker
>>> DB::connection()->getPdo();
# Should return PDO object without errors
```

### 2. Test pgvector

```bash
docker exec -it whatsapp_chatbot_db psql -U postgres -d whatsapp_chatbot -c "SELECT '[1,2,3]'::vector;"
# Should return: [1,2,3]
```

### 3. Test WhatsApp Webhook

```bash
# Check webhook verification
curl "http://localhost/api/webhook/whatsapp?hub.mode=subscribe&hub.verify_token=my_fyp_chatbot_2024&hub.challenge=test123"
# Should return: test123
```

### 4. Test OpenAI Connection

```bash
php artisan tinker
>>> app(App\Services\OpenAIService::class)->testConnection();
# Should return success message
```

---

## 📊 Development Workflow

### Daily Development

```bash
# 1. Start Laragon
#    (Just open Laragon and click "Start All")

# 2. Start PostgreSQL container
docker-compose up -d

# 3. Start frontend dev server
npm run dev

# 4. Start ngrok for webhook (if testing WhatsApp)
ngrok http 80

# 5. Open browser: http://whatsapp-chatbot.test

# 6. Code and test!

# 7. When done
#    - Stop Laragon (click "Stop All")
#    - Stop Docker: docker-compose down
```

### After Pulling New Code

```bash
composer install
npm install
php artisan migrate
```

---

## 👨‍🎓 Project Info

**Type**: Final Year Project  
**Environment**: Local Development (Laragon + Docker)  
**Deployment**: Not required (presentation only)

---

## 📄 License

This project is for educational purposes only.