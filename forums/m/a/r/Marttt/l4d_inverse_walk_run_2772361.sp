public Plugin myinfo = { name = "[L4D1 & L4D2] Inverse Walk/Run", author = "Mart" }

static int WALK_BUTTONS = (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT);

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (IsFakeClient(client))
        return Plugin_Continue;

    if (buttons & IN_SPEED)
    {
        buttons &= ~IN_SPEED;
        return Plugin_Changed;
    }

    if (buttons & WALK_BUTTONS)
    {
        buttons |= IN_SPEED;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}