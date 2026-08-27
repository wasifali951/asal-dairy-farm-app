# Payment Server Setup

## Overview
This is a sample Node.js/Express server that integrates with JazzCash for mobile payments in Pakistan.

## Installation

```bash
cd server
npm install
```

## Configuration

Create a `.env` file in the `server/` directory:

```env
PORT=3000
JAZZCASH_MERCHANT_ID=your_merchant_id
JAZZCASH_MERCHANT_PASSWORD=your_merchant_password
JAZZCASH_PP_MERCHANT_ID=your_pp_merchant_id
JAZZCASH_RETURN_URL=http://localhost:3000/payment/callback
```

Get these credentials from [JazzCash Dashboard](https://sandbox.jazzcash.com.pk/).

## Running

```bash
npm start       # Production
npm run dev     # Development with auto-reload
```

## API Endpoints

### 1. POST `/payment/request`
Request a payment from the mobile app.

**Request:**
```json
{
  "amount": 500,
  "orderId": "ORDER-123",
  "phone": "03001234567",
  "email": "customer@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "transactionId": "TXN-1672531200000",
  "paymentUrl": "https://sandbox.jazzcash.com.pk/ApplicationAPI/API/Payment/DoTransaction?...",
  "orderId": "ORDER-123",
  "amount": 500
}
```

### 2. POST `/payment/callback`
JazzCash redirects here after payment attempt. Verifies HMAC-SHA256 signature.

### 3. GET `/payment/query/:orderId`
(Optional) Query payment status for reconciliation.

## Sample Implementation

See `payment_server_sample.txt` for the complete Node.js/Express code.

## Integration with Flutter App

1. In `lib/main.dart`, update `PaymentProvider` to call your server:
   ```dart
   final response = await http.post(
     Uri.parse('http://your-server.com/payment/request'),
     body: jsonEncode({'amount': amount, 'orderId': orderId}),
   );
   ```

2. Navigate to `WebViewPaymentScreen` with the returned `paymentUrl`.

3. Handle the callback redirect via deep links or return status.

## Security Checklist

- ✅ Verify HMAC-SHA256 signatures on all callbacks
- ✅ Store merchant password securely (never in app or frontend)
- ✅ Use HTTPS in production
- ✅ Validate amount and order status before processing
- ✅ Log all transactions for audit trail

## Next Steps

- Replace sandbox credentials with production credentials when ready
- Implement database storage for transactions
- Add user authentication on server endpoints
- Set up monitoring and alerting
- Test with real JazzCash test accounts

