export default class ErrorService {
  static handle(error) {
    console.error(error);
    alert('Error: ' + error.message);
  }
}
