import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test late initialization error reproduction', () {
    final testClass = TestClass();
    try {
      // This should throw a LateInitializationError if _data is accessed before initialization
      testClass.useData();
      fail('Should have thrown a LateInitializationError');
    } catch (e) {
      expect(e.toString().contains('LateInitializationError'), isTrue);
    }
  });
}

class TestClass {
  late List<String> _data;

  // This method tries to use _data without initializing it first
  void useData() {
    print('Data length: ${_data.length}');
  }

  // This method should be called to prevent the error
  void initializeData() {
    _data = [];
  }
}
