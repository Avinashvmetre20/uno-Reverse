class AuthPolicy {
  static const pinLength = 4;
  static const maxPinAttempts = 5;
  static const pinLockout = Duration(seconds: 60);
  static const backgroundLock = Duration(seconds: 60);
  static const requestTimeout = Duration(seconds: 20);
  static const accessSkew = Duration(seconds: 30);

  static const trivialPins = {
    '0000',
    '1111',
    '2222',
    '3333',
    '4444',
    '5555',
    '6666',
    '7777',
    '8888',
    '9999',
    '1234',
    '4321',
    '0123',
    '9876',
    '1212',
    '2580',
  };
}
