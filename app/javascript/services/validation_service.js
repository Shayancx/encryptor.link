export default class ValidationService {
  static validate({ message = '', ttl = 0, views = 0 }) {
    if (ttl <= 0) return 'Invalid expiration time';
    if (views <= 0) return 'Invalid view limit';
    return null;
  }
}
