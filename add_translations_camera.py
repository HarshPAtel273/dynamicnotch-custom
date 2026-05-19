import json

file_path = '/Users/macintosh/Documents/GitHub/DynamicNotch/DynamicNotch/Resources/Localization/Localizable.xcstrings'

with open(file_path, 'r') as f:
    data = json.load(f)

new_strings = {
    "settings.permissions.camera.title": {
        "ru": "Камера",
        "en": "Camera"
    },
    "settings.permissions.camera.description": {
        "ru": "Разрешите доступ к камере для отображения превью в вырезе.",
        "en": "Allow Camera access to display a camera preview in the notch."
    }
}

for key, translations in new_strings.items():
    if key not in data['strings']:
        data['strings'][key] = {
            "extractionState": "manual",
            "localizations": {}
        }
    for lang, translation in translations.items():
        if "localizations" not in data['strings'][key]:
            data['strings'][key]["localizations"] = {}
        data['strings'][key]["localizations"][lang] = {
            "stringUnit": {
                "state": "translated",
                "value": translation
            }
        }

with open(file_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Added translations successfully")
