from os.path import join

PATCH_LIST = [
    "RECIPENAME",
    "MODULE_NAME",
    "MODULE_FOLDER",
    "CUSTOM_ROOT",
    "PY_VERSION",
    "OSX_VERSION"
    
    ]


def create_recipe(app_dir: str, recipe_dict: dict) -> str:

    with open(join(app_dir,"build_files","kivy_recipe.py")) as f:
        kivy_recipe = str(f.read())

    d = recipe_dict
    new_recipe = kivy_recipe

    for patch in PATCH_LIST:
        if patch == "RECIPENAME":
            new_recipe = new_recipe.replace("RECIPENAME",d["module_title"])
        elif patch in ("MODULE_FOLDER", "CUSTOM_ROOT"):
            if d[patch] != None:
                new_recipe = new_recipe.replace(patch,f"{d[patch]}")
            else:
                new_recipe = new_recipe.replace(f"\"{patch}\"",f"{d[patch]}")
        else:
            new_recipe = new_recipe.replace(patch,f"{d[patch]}")

    return new_recipe