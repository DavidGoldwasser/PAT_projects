

###### (Automatically generated documentation)

# Change Zone Multiplier by Building Story

## Description
This measure will loop through all spaces on user specified bulidng story and will increase the multiplier by a user suplied multiplier. Matched floor/ceiling surfaces with zones that no longer have the same boundary condition will be chagned to adiabaitc

## Modeler Description
This will not just set the multiplier to the user specified value. Instead it will take the original value and multiplier it by the user specified value. So if the user specifed value is 2.0, and a zone started with a multiplier of 3.0 it would be changed to 6.0. A zone starting at 1.0 would chagne to 2.0. If a zone contains spaces from two different stories, including the user specified story the measure will error instead of attempting to change the zone multipliers. The measure will also error if the spaces on the selected story have any roofs or floors with exterior or ground exposure.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Choose a building story to alter zone multipliers for.

**Name:** building_story,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Thermal zone multiplier adjustment
The existing thermal zone multiplier for zones that contain spaces on this story will be multiplied by this value.
**Name:** multiplier_adj,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false




