# encryptor.link

A zero-knowledge, client-side encrypted message and file sharing service. Send encrypted messages and files that self-destruct after being viewed.

![encryptor.link](https://via.placeholder.com/1200x600?text=encryptor.link)

## Features

- 🔒 **Zero-knowledge encryption**: All encryption and decryption happens in your browser
- 💥 **Self-destructing messages**: Messages expire after viewing or a set time period
- 📁 **File sharing**: Send encrypted files up to 1000MB
- 🔑 **Client-side security**: The server never sees your unencrypted data
- 🌓 **Dark/light mode**: Toggle between themes for comfortable viewing
- 📱 **Responsive design**: Works on desktop and mobile devices

## How It Works

1. Your message/files are encrypted in your browser using AES-GCM encryption
2. The encryption key is kept in the URL fragment (#) and never sent to the server
3. Only encrypted data is transmitted to and stored on the server
4. When the recipient opens the link, their browser downloads the encrypted data and decrypts it locally
5. Once viewed, the message is deleted from the server and cannot be accessed again

## Security

- Uses the Web Crypto API with AES-GCM for strong encryption
- Encryption/decryption keys are never transmitted to the server
- Messages automatically expire after viewing or a configured time period
- No account required, no logs of message content
- Open source - inspect the code to verify security

## Development

### Prerequisites

- Ruby 3.4.3
- PostgreSQL
- Node.js 22.14.0 or later

### Setup

1. Clone the repository
```bash
git clone https://github.com/Shayancx/encryptor.link.git
cd encryptor.link
```

2. Install dependencies
```bash
bundle install
```

3. Setup the database
```bash
bin/rails db:create db:migrate
```

4. Start the application
```bash
bin/dev
```

5. Visit http://localhost:3000 in your browser

### Testing

```bash
bin/rails test
```

### Linting

```bash
bin/rubocop
```

## Technical Stack

- **Backend**: Ruby 3.4.3, Rails 8.0.2
- **Database**: PostgreSQL
- **Frontend**: Bootstrap 5.3, Stimulus, JavaScript
- **Encryption**: Web Crypto API (AES-GCM)
- **Job Processing**: Solid Queue

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Web Crypto API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Crypto_API)
- [Bootstrap](https://getbootstrap.com/)
- [Ruby on Rails](https://rubyonrails.org/)

## Disclaimer

This software is provided for educational and personal use only. No security system is perfect. Use at your own risk.
