int hexStringToInt(String hexString) =>
    int.parse("0xFF${hexString.substring(1)}");
