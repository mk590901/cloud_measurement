import "dart:convert";

class DataModel {
  String id = "";
  String value = "";

  DataModel({required this.id, required this.value});

  // DataModel.fromJson(Map<String, dynamic> json) {
  //   id = json['id'].toString();
  //   value = json['value'].toString();
  // }

  DataModel.fromJson(String jsonText) {
    Map<String, dynamic> map = json.decode(jsonText);
    id = map['i'].toString();
    value = map['v'].toString();
  }

  Map<String, String> toJson() {
    final Map<String, String> data = <String, String>{};
    data['i'] = id;
    data['v'] = value;
    return data;
  }
}
