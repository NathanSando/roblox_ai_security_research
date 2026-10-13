import json

# Write data into a JSON file.
def export_data(data_set):
    with open("user_data.json", "w", encoding = "utf-8") as file:
        json.dump(data_set, file, indent = 4)


