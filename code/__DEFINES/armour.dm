// Armor defines for the new armor system.

#define ARMOR_CONSTANT 50
#define ARMOR_EQUATION(damage, armor, modifier) (armor <= -ARMOR_CONSTANT ? INFINITY : (damage / (1 + (armor / ARMOR_CONSTANT))) * modifier)
#define ARMOR_PERCENTAGE_TO_VALUE(percentage) (percentage >= 100 ? INFINITY : (5000 / (100 - percentage)) - 50)
#define ARMOR_VALUE_TO_PERCENTAGE(value) (value == INFINITY ? 100 : round((100 - (100 / (1 + (value / ARMOR_CONSTANT)))), 0.01))
