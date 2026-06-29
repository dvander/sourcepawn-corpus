#include <sdktools> 

new String:list_models[][] = { 

    "models/player/example/model.mdl", 

    "models/player/rebel/male_01.mdl", 
    "models/player/rebel/male_02.mdl", 
    "models/player/rebel/male_03.mdl", 
    "models/player/rebel/male_04.mdl", 
    "models/player/rebel/male_05.mdl", 
    "models/player/rebel/male_06.mdl", 
    "models/player/rebel/male_07.mdl", 
    "models/player/rebel/male_08.mdl", 
    "models/player/rebel/male_09.mdl", 
    "models/player/rebel/female_01.mdl", 
    "models/player/rebel/female_02.mdl", 
    "models/player/rebel/female_03.mdl", 
    "models/player/rebel/female_04.mdl", 
    "models/player/rebel/female_05.mdl", 
    "models/player/rebel/female_06.mdl", 
    "models/player/rebel/female_07.mdl", 
    "models/player/rebel/hero_male.mdl", 
    "models/player/rebel/hero_female.mdl" 

} 


public OnPluginStart() 
{ 
    RegConsoleCmd("sm_models", test); 
} 

public Action:test(client, args) 
{ 

    new Handle:menu = CreateMenu(menu_handler); 
    SetMenuTitle(menu, "Models"); 

    new list_models_size = sizeof(list_models); 
    new tmp; 

    for(new a = 0; a < list_models_size; a++) 
    { 
        tmp = FindCharInString(list_models[a], '.', true); 

        if(StrEqual(list_models[a][tmp], ".mdl", false) && FileExists(list_models[a], true)) 
        { 
            tmp = FindCharInString(list_models[a], '/', true)+1; 
            AddMenuItem(menu, list_models[a], list_models[a][tmp]); 
        } 
    } 
    DisplayMenu(menu, client, 60); 
    return Plugin_Handled; 
} 

public menu_handler(Handle:menu, MenuAction:action, param1, param2) 
{ 
    switch(action) 
    { 
        case MenuAction_End: 
        { 
            CloseHandle(menu); 
        } 
        case MenuAction_Select: 
        { 
            new String:infoBuf[PLATFORM_MAX_PATH]; 
            GetMenuItem(menu, param2, infoBuf, sizeof(infoBuf)); 
            PrecacheModel(infoBuf); 
            SetEntityModel(param1, infoBuf); 

            test(param1, 0); 
        } 
    } 
}  