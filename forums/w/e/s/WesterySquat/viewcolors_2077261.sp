#include <sourcemod>
#include <morecolors>
 
public Plugin:myinfo =
{
        name = "ViewColors",
        author = "Westery",
        description = "View colors of the more colors.",
        version = "0.2",
        url = "http://forum.supreme-elite.fr"
}
 
new String:info[161]; /* création variable pour prendre le steam id */
new String:info2[40]; /* création variable prendre le color */
 
public OnPluginStart()
{
    RegConsoleCmd("sm_viewcolors", Command_Menu); /* création commande menu */
}
 
stock menucolor(client)
{
        new Handle:menu = CreateMenu(MenuHandler, MENU_ACTIONS_ALL);
        SetMenuTitle(menu, "< ViewColors by Westery >");
        AddMenuItem(menu, "{aliceblue}", "Alice Blue");
        AddMenuItem(menu, "{allies}", "Allies");
        AddMenuItem(menu, "{antiquewhite}", "Antique White");
        AddMenuItem(menu, "{aqua}", "Aqua");
        AddMenuItem(menu, "{aquamarine}", "Aqua Marine");
        AddMenuItem(menu, "{axis}", "Axis");
        AddMenuItem(menu, "{azure}", "Azure");
        AddMenuItem(menu, "{beige}", "Beige");
        AddMenuItem(menu, "{bisque}", "Bisque");
        AddMenuItem(menu, "{black}", "Black");
        AddMenuItem(menu, "{blanchedalmond}", "Blanche Dalmond");
        AddMenuItem(menu, "{blue}", "Blue");
        AddMenuItem(menu, "{blueviolet}", "Blue Violet");
        AddMenuItem(menu, "{brown}", "Brown");
        AddMenuItem(menu, "{burlywood}", "Burly Wood");
        AddMenuItem(menu, "{cadetblue}", "Cadet Blue");
        AddMenuItem(menu, "{chartreuse}", "Chartreuse");
        AddMenuItem(menu, "{chocolate}", "Chocolate");
        AddMenuItem(menu, "{community}", "Community");
        AddMenuItem(menu, "{coral}", "Coral");
        AddMenuItem(menu, "{cornflowerblue}", "Corn Flower Blue");
        AddMenuItem(menu, "{cornsilk}", "Cornsilk");
        AddMenuItem(menu, "{crimson}", "Crimson");
        AddMenuItem(menu, "{cyan}", "Cyan");
        AddMenuItem(menu, "{darkblue}", "Dark Blue");
        AddMenuItem(menu, "{darkcyan}", "Dark Cyan");
        AddMenuItem(menu, "{darkfoldenrod}", "Dark Goldenrod");
        AddMenuItem(menu, "{darkgray}", "Dark Gray");
        AddMenuItem(menu, "{darkgrey}", "Dark Grey");
        AddMenuItem(menu, "{darkgreen}", "Dark Green");
        AddMenuItem(menu, "{darkkhaki}", "Dark Khaki");
        AddMenuItem(menu, "{darkmagenta}", "Dark Magenta");
        AddMenuItem(menu, "{darkolivegreen}", "Dark Olive Green");
        AddMenuItem(menu, "{darkorange}", "Dark Orange");
        AddMenuItem(menu, "{darkorchid}", "Dark Ochid");
        AddMenuItem(menu, "{darkred}", "Dark Red");
        AddMenuItem(menu, "{darksalmon}", "Dark Salmon");
        AddMenuItem(menu, "{darkseagreen}", "Dark Sea Green");
        AddMenuItem(menu, "{darkslateblue}", "Dark Slate Blue");
        AddMenuItem(menu, "{darkslategray}", "Dark Slate Gray");
        AddMenuItem(menu, "{darkslategrey}", "Dark Slate Grey");
        AddMenuItem(menu, "{darkturquoise}", "Dark Turquoise");
        AddMenuItem(menu, "{darkviolet}", "Dark Violet");
        AddMenuItem(menu, "{deeppink}", "Deep Pink");
        AddMenuItem(menu, "{deepskyblue}", "Dark Sky Blue");
        AddMenuItem(menu, "{dimgray}", "Dim Gray");
        AddMenuItem(menu, "{dimgrey}", "Dim Grey");
        AddMenuItem(menu, "{dodgerblue}", "Dodger Blue");
        AddMenuItem(menu, "{firebrick}", "Firebrick");
        AddMenuItem(menu, "{floralwhite}", "Floral White");
        AddMenuItem(menu, "{forestgreen}", "Forest Green");
        AddMenuItem(menu, "{fuchsia}", "Fuchsia");
        AddMenuItem(menu, "{fullblue}", "Full Blue");
        AddMenuItem(menu, "{fullred}", "Full Red");
        AddMenuItem(menu, "{gainsboro}", "Gainsboro");
        AddMenuItem(menu, "{genuine}", "Genuine");
        AddMenuItem(menu, "{ghostwhite}", "Ghost White");
        AddMenuItem(menu, "{gold}", "Gold");
        AddMenuItem(menu, "{goldenrod}", "Golden Rod");
        AddMenuItem(menu, "{gray}", "Gray");
        AddMenuItem(menu, "{grey}", "Grey");
        AddMenuItem(menu, "{green}", "Green");
        AddMenuItem(menu, "{greenyellow}", "Green Yellow");
        AddMenuItem(menu, "{haunted}", "Haunted");
        AddMenuItem(menu, "{honeydew}", "Honey Drew");
        AddMenuItem(menu, "{hotpink}", "Hot Pink");
        AddMenuItem(menu, "{indianred}", "Indian Red");
        AddMenuItem(menu, "{indigo}", "Indigo");
        AddMenuItem(menu, "{ivory}", "Ivory");
        AddMenuItem(menu, "{khaki}", "Khaki");
        AddMenuItem(menu, "{lavender}", "Lavender");
        AddMenuItem(menu, "{lavenderblush}", "Lavender Blush");
        AddMenuItem(menu, "{lawngreen}", "Lawn Green");
        AddMenuItem(menu, "{lemonchiffon}", "Lemon Chiffon");
        AddMenuItem(menu, "{lightblue}", "Light Blue");
        AddMenuItem(menu, "{lightcoral}", "Light Coral");
        AddMenuItem(menu, "{lightcyan}", "Light Cyan");
        AddMenuItem(menu, "{lightgreen}", "Light Green");
        AddMenuItem(menu, "{lightpink}", "Light pink");
        AddMenuItem(menu, "{lightsalmon}", "Light Salmon");
        AddMenuItem(menu, "{lightseagreen}", "Light Sea Green");
        AddMenuItem(menu, "{lightskyblue}", "Light Sky Blue");
        AddMenuItem(menu, "{lightslategray}", "Light Slate Gray");
        AddMenuItem(menu, "{lightslategrey}", "Light Slate Grey");
        AddMenuItem(menu, "{lightsteelblue}", "Light Steel Blue");
        AddMenuItem(menu, "{lightyellow}", "Light Yellow");
        AddMenuItem(menu, "{lime}", "Lime");
        AddMenuItem(menu, "{limegreen}", "Lime Green");
        AddMenuItem(menu, "{linen}", "Linen");
        AddMenuItem(menu, "{magenta}", "Magenta");
        AddMenuItem(menu, "{maroon}", "Maroon");
        AddMenuItem(menu, "{mediumaquamarine}", "Medium Aqua Marine");
        AddMenuItem(menu, "{mediumblue}", "Medium Blue");
        AddMenuItem(menu, "{mediumorchid}", "Medium Orchid");
        AddMenuItem(menu, "{mediumpurple}", "Medium Purple");
        AddMenuItem(menu, "{mediumseagreen}", "Medium Sea Green");
        AddMenuItem(menu, "{mediumslateblue}", "Medium Slate Blue");
        AddMenuItem(menu, "{mediumspringgreen}", "Medium Spring Green");
        AddMenuItem(menu, "{mediumturquoise}", "Medium Turquoise");
        AddMenuItem(menu, "{mediumvioletred}", "Medium Violet Red");
        AddMenuItem(menu, "{midnightblue}", "Midnight Blue");
        AddMenuItem(menu, "{mintcream}", "Mint Cream");
        AddMenuItem(menu, "{mistyrose}", "Misty Rose");
        AddMenuItem(menu, "{moccasin}", "Moccasin");
        AddMenuItem(menu, "{navajowhite}", "Navajo White");
        AddMenuItem(menu, "{navy}", "Navy");
        AddMenuItem(menu, "{oldlace}", "Oldlace");
        AddMenuItem(menu, "{olive}", "Olive");
        AddMenuItem(menu, "{olivedrab}", "Olive Drab");
        AddMenuItem(menu, "{orange}", "Orange");
        AddMenuItem(menu, "{orangered}", "Orange Red");
        AddMenuItem(menu, "{orchid}", "Orchid");
        AddMenuItem(menu, "{palegoldenrod}", "Pale Golden Rod");
        AddMenuItem(menu, "{palegreen}", "Pale Green");
        AddMenuItem(menu, "{paleturquoise}", "Pale Turquoise");
        AddMenuItem(menu, "{palevioletred}", "Pale Violet Red");
        AddMenuItem(menu, "{papayawhip}", "Papaya Whip");
        AddMenuItem(menu, "{peachpuff}", "Peach Puff");
        AddMenuItem(menu, "{peru}", "Peru");
        AddMenuItem(menu, "{pink}", "Pink");
        AddMenuItem(menu, "{plum}", "Plum");
        AddMenuItem(menu, "{powderblue}", "Powder Blue");
        AddMenuItem(menu, "{purple}", "Purple");
        AddMenuItem(menu, "{red}", "Red");
        AddMenuItem(menu, "{rosybrown}", "Rosy Brown");
        AddMenuItem(menu, "{royalblue}", "Royal Blue");
        AddMenuItem(menu, "{saddlebrown}", "Saddle Brown");
        AddMenuItem(menu, "{salmon}", "Salmon");
        AddMenuItem(menu, "{sandybrown}", "Sandy Brown");
        AddMenuItem(menu, "{seagreen}", "Sea Green");
        AddMenuItem(menu, "{seashell}", "Sea Shell");
        AddMenuItem(menu, "{selfmade}", "Selfmade");
        AddMenuItem(menu, "{sienna}", "Sienna");
        AddMenuItem(menu, "{silver}", "Silver");
        AddMenuItem(menu, "{skyblue}", "Skye Blue");
        AddMenuItem(menu, "{slateblue}", "Slate Blue");
        AddMenuItem(menu, "{slategray}", "Slate Gray");
        AddMenuItem(menu, "{slategrey}", "Slate Grey");
        AddMenuItem(menu, "{snow}", "Snow");
        AddMenuItem(menu, "{springgreen}", "Spring Green");
        AddMenuItem(menu, "{steelblue}", "Steelblue");
        AddMenuItem(menu, "{strange}", "Strange");
        AddMenuItem(menu, "{tan}", "Tan");
        AddMenuItem(menu, "{teal}", "Teal");
        AddMenuItem(menu, "{thistle}", "Thistle");
        AddMenuItem(menu, "{tomato}", "Tomato");
        AddMenuItem(menu, "{turquoise}", "Turquoise");
        AddMenuItem(menu, "{unique}", "Unique");
        AddMenuItem(menu, "{unusual}", "Unusual");
        AddMenuItem(menu, "{valve}", "Valve");
        AddMenuItem(menu, "{vintage}", "Vintage");
        AddMenuItem(menu, "{violet}", "Violet");
        AddMenuItem(menu, "{wheat}", "Wheat");
        AddMenuItem(menu, "{white}", "White");
        AddMenuItem(menu, "{whitesmoke}", "White Smoke");
        AddMenuItem(menu, "{yellow}", "Yellow");
        AddMenuItem(menu, "{yellowgreen}", "Yellow Green");
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
 
public Action:Command_Menu(client, args)
{
    menucolor(client);
    return Plugin_Handled;
}
 
public MenuHandler(Handle:menu, MenuAction:action, client, param2)
{
    if ( action == MenuAction_Select )
    {
		decl String:info[40];
		GetMenuItem(menu, param2, info, sizeof(info));
        CPrintToChat(client, "%sThis is the graphic rendering of the selected color.%s", info, info2);
        menucolor(client);
    }
}