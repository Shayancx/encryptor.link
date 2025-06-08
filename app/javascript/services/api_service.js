import CSRFHelper from '../lib/csrf-helper';

export default class ApiService {
  static postEncrypt(payload) {
    return CSRFHelper.fetchWithCSRF('/encrypt', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
  }
}
