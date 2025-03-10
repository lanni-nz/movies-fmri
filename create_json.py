import json

def create_json():
    descriptions = []

    # Anatomical data
    anat_input = input("Does the data have anatomical files? (y/n): ").strip().lower()
    if anat_input == 'y':
        anat_desc = input("Name or series description of anatomical data: ").strip()
        descriptions.append({
            "datatype": "anat",
            "suffix": "T1w",
            "criteria": {"SeriesDescription": anat_desc}
        })

    # Fieldmap data
    fmap_input = input("Does the data have fieldmap files? (y/n): ").strip().lower()
    if fmap_input == 'y':
        fmap_desc = input("Name or series description of fieldmap data: ").strip()
        descriptions.append({
            "datatype": "fmap",
            "suffix": "epi",
            "criteria": {"SeriesDescription": fmap_desc}
        })

    # Functional data
    func_input = input("Does the data have functional files? (y/n): ").strip().lower()
    while func_input == 'y':
        func_type = input("Enter the type of functional data (task/rest/video): ").strip().lower()
        func_desc = input("Name or series description of functional data: ").strip()
        entry = {
            "datatype": "func",
            "suffix": "bold",
            "criteria": {"SeriesDescription": func_desc}
        }

        if func_type == "task":
            task_name = input("Enter the task name: ").strip()
            entry["customLabels"] = "task"
            entry["sidecarChanges"] = {"TaskName": task_name}

        descriptions.append(entry)
        func_input = input("Do you want to add another functional dataset? (y/n): ").strip().lower()

    # Save to JSON
    output = {"descriptions": descriptions}
    with open("output.json", "w") as f:
        json.dump(output, f, indent=2)

    print("JSON file 'output.json' has been created successfully.")

# Run the function
create_json()
