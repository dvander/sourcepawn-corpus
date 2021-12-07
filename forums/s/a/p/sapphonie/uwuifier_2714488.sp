#pragma semicolon 1

#include <sourcemod>
#include <scp>

public Plugin:myinfo =
{
    name        = "uwuifier",
    author      = "stephanie",
    description = "uwu",
    version     = "0.0.6",
    url         = "https://steph.anie.dev/"
};

char faces[][] = {
    " owo",
    " UwU",
    " >w<",
    " ^w^",
    " OwO",
    " :3",
    " >:3",
    "~"
};

public Action OnChatMessage(&author, Handle recipients, char[] name, char[] message)
{
    ReplaceString(message, MAXLENGTH_MESSAGE, "l", "w", true);
    ReplaceString(message, MAXLENGTH_MESSAGE, "r", "w", true);
    ReplaceString(message, MAXLENGTH_MESSAGE, "L", "W", true);
    ReplaceString(message, MAXLENGTH_MESSAGE, "R", "W", true);

    // 1/3rd chance to append a face
    if (GetRandomInt(1, 6) > 4)
    {
        // get one of the 8 faces
        int randFace = GetRandomInt(0, 7);
        StrCat(message, MAXLENGTH_MESSAGE, faces[randFace]);
    }

    return Plugin_Handled;
}
