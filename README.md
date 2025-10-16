# Godot - DTag

DTag, a tool for creating tag like "GameplayTag" in Unreal Engine.

The essence of DTag is `StringName`, this plugin provide tool to generate structured constant `Dictionary`, and provide editor inspector plugin to select **tag** and **tag domain**.

## How to use (Basic):

### Step1: Define your tags.

Exclude "res://addons/", including internal class in GDScript, any type which extends from `DTagDefinition` will be scanned.

For example:
```GDScript
# res://dtag_example.gd
extends DTagDefinition

const MainDomain1 = {
    Domain1 = {
        Tag1 = "Example tag1", # Case 1：Use String/StringName as value will be recognized as comment in generated script.
        Tag2 = null, # Case 2：Use "null" as value will be recognized as tag, too.
    },
    Tag3 = "", # Case 3：Empty string as value will be recognized as tag, too.
}

class InternalClass extends DTagDefinition:
    const MainDomain2 = {
        Domain2 = {
            Tag1 = "Example tag",
            Tag2 = "Example tag",
        }
    }
...

```

### Step2: Generate tag def.

By using "Project->Tool->Generate dtag_def.gen.gd", "res://dtag_def.gen.gd" will be generated.

![](.doc/step2.png)

Here is the generated file of step1.
```GDScript
# res://dtag_def.gen.gd
# NOTE: This file is generated, any modify maybe discard.
class_name DTagDef


const MainDomain1 = {
	Domain1 = {
		## Example tag1
		Tag1 = &"MainDomain1.Domain1.Tag1",
		Tag2 = &"MainDomain1.Domain1.Tag2",
	},
	Tag3 = &"MainDomain1.Tag3",
}

```

### Step3: Just use it.

Now you can use tags through `DTagDef`.

```

func example() -> void:
    var example_tag1 := DTagDef.MainDomain1.Domain1.Tag1
    print(example_tag1) # Output &"MainDomain1.Domain1.Tag1"


```


## How to use (Advance):

    The section is assume that your are completely master the previous section.

This plugin provide an EditorInspectorPlugin to edit tag/tag domain through inspector by using a special selector.

### 1. Use resource `DTag`

`DTag` has properties `value/tag(alias of "value" for inspector)` and `domain`.


### 2. Custom property with specific hint_string:

- Export `StringName`/`String` property with hint string "**DTagEdit**".

    **Advance**: You can specific tag's domain, for example, Use "DTagEdit: MainDomain1.Domain1", you can limit choices in the domain "MainDomain1.Domain1".

    Example: 
    ```
    # This can select any tag in inspector.
    @export_custom(PROPERTY_HINT_NONE, "DTagEdit") var tag1: StringName

    # This will limit domain in "MainDomain1.Domain1".
    @export_custom(PROPERTY_HINT_NONE, "DTagEdit: MainDomain1.Domain1") var tag2: StringName

    ```

- Export `Array/Array[StringName]/Array[String]/PackedStringName` property with hint string "DTagDomainEdit".