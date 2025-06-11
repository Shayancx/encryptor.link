# Encryptor.link

A zero-knowledge, end-to-end encrypted messaging service that lets you share self-destructing messages and files with no accounts required. Your data never leaves your browser unencrypted.

## Features

- **End-to-end encryption** using modern Web Cryptography API
- **Self-destructing messages** with expiration times and view limits
- **No accounts required** - just create a message and share the link
- **Zero knowledge** - the server never sees unencrypted data
- **File sharing** with the same level of encryption as messages
- **QR code generation** for easy sharing

## Technical Stack

- **Frontend**: React, TypeScript, Vite, Tailwind CSS, Shadcn UI
- **Backend**: Ruby on Rails API
- **Encryption**: Web Cryptography API, CryptoJS

## Development Setup

### Prerequisites

- Ruby (see `.ruby-version`)
- Node.js (recommended 16+)
- PostgreSQL
- Yarn or npm

### Installation

1. Clone the repository
   ```
   git clone https://github.com/Shayancx/encryptor.link.git
   cd encryptor.link
   ```

2. Install dependencies
   ```
   bundle install
   npm install
   ```

3. Set up the database
   ```
   bin/rails db:create db:migrate
   ```

4. Start the development servers
   ```
   ./start-servers.sh
   ```
   
   Or manually:
   - Rails server: `bin/rails server -p 3000`
   - Vite dev server: `npm run dev`

5. Visit http://localhost:5173 to access the application

## Architecture

### Frontend Architecture

- **React + TypeScript**: For robust front-end development with static typing
- **Vite**: For fast development and optimized production builds
- **Tailwind CSS & Shadcn UI**: For responsive, beautiful UI components
- **Web Cryptography API**: For secure client-side encryption/decryption
- **React Router**: For client-side routing

### Backend Architecture

- **Ruby on Rails**: Serving as a lightweight API
- **PostgreSQL**: Primary database
- **Redis**: For caching and background job processing (if needed)

### Security Architecture

- **Zero-knowledge principle**: All encryption/decryption happens in the browser
- **Modern encryption**: Using AES-GCM with the Web Cryptography API
- **CSRF protection**: Preventing cross-site request forgery
- **Content Security Policy**: Restricting resource loading
- **Sanitized content**: Preventing XSS attacks

## Deployment

For production deployment, see the deployment guide in `docs/deployment.md`.

## Contributing

Contributions are welcome! Please see our [Contributing Guide](CONTRIBUTING.md) for more information.

## License

This project is licensed under the [MIT License](LICENSE).
