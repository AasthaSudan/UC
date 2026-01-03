class PredictedPlaces {
  String? placeId;
  String? mainText;
  String? secondaryText;

  PredictedPlaces({
    this.placeId,
    this.mainText,
    this.secondaryText,
  });

  PredictedPlaces.fromJson(Map<String, dynamic> json) {
    placeId = json["place_id"];
    mainText = json["structured_formatting"]["main_text"];
    secondaryText = json["structured_formatting"]["secondary_text"];
  }
}