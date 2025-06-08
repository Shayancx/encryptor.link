import { encryptMessage, encryptFiles } from '../lib/encrypt';

export default class CryptographyService {
  static encryptMessage(...args) {
    return encryptMessage(...args);
  }

  static encryptFiles(...args) {
    return encryptFiles(...args);
  }
}
