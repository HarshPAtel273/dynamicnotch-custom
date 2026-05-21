import json

file_path = '/Users/macintosh/Documents/GitHub/DynamicNotch/DynamicNotch/Resources/Localization/Localizable.xcstrings'

with open(file_path, 'r') as f:
    data = json.load(f)

new_strings = {
    "Home Page activity": {
        "ru": "Активность домашней страницы",
        "es": "Actividad de la página de inicio",
        "zh-Hans": "主页活动"
    },
    "Home Page live activity": {
        "ru": "Live Activity домашней страницы",
        "es": "Actividad en vivo de la página de inicio",
        "zh-Hans": "主页实时活动"
    },
    "Show the Home Page in the notch.": {
        "ru": "Показывать домашнюю страницу в вырезе.",
        "es": "Muestra la página de inicio en la muesca.",
        "zh-Hans": "在刘海中显示主页。"
    }
}

for key, translations in new_strings.items():
    if key not in data['strings']:
        data['strings'][key] = {
            "extractionState": "manual",
            "localizations": {
                "en": {
                    "stringUnit": {
                        "state": "translated",
                        "value": key
                    }
                }
            }
        }
        for lang, translation in translations.items():
            data['strings'][key]["localizations"][lang] = {
                "stringUnit": {
                    "state": "translated",
                    "value": translation
                }
            }

with open(file_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Added translations successfully")
