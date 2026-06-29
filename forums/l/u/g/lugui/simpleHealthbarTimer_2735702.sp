/*
 * This is not a very practical plugin to use.
 * It was made to be used as an example for doing simmilar calculations.
 */

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
	name = "Simple Healthbar",
	author = "lugui",
	description = "Displays a healthbar on top of other players.",
	version = "1.0.0",
}

int beamSprite;
int glowsprite;

public OnMapStart() {
    beamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    glowsprite = PrecacheModel("sprites/redglow3.vmt");
    CreateTimer(0.1, Timer_Render, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Render(Handle timer){
    for(int i = 1; i < MaxClients; i++) {
        if(isValidClient(i)){
            renderHealthbar(i);
        }
    }
}

void renderHealthbar(int client) {
    float clientPos[3];
    GetClientEyePosition(client, clientPos);

    for(int target = 1; target < MaxClients; target++) {
        if(isValidClient(target, true) && target != client && IsPlayerAlive(target)) {
            // Everyone will see everyone's bar, axept for its own.
            float targetPos[3];
            GetClientEyePosition(target, targetPos);

            targetPos[2] += 10.0;

            float vecPos[3];
            MakeVectorFromPoints(targetPos, clientPos, vecPos);

            float clientAng[3];
            GetVectorAngles( vecPos, clientAng );

            float radius = 50.0;

            // To avoid getting the pointer instead of the actual value (IDK if that is right)
            float targetMin[3];
            targetMin[0] = targetPos[0];
            targetMin[1] = targetPos[1];
            targetMin[2] = targetPos[2];

            float targetMax[3];
            targetMax[0] = targetPos[0];
            targetMax[1] = targetPos[1];
            targetMax[2] = targetPos[2];

            float targetCurrent[3];
            targetCurrent[0] = targetPos[0];
            targetCurrent[1] = targetPos[1];
            targetCurrent[2] = targetPos[2];

            // Left
            clientAng[1] += 90.0;
            targetMax[0] += radius * Cosine( DegToRad( clientAng[1] ));
            targetMax[1] += radius * Sine( DegToRad( clientAng[1] ));

            // Right Max
            clientAng[1] -= 180.0;
            targetMin[0] += radius * Cosine( DegToRad( clientAng[1] ));
            targetMin[1] += radius * Sine( DegToRad( clientAng[1] ));

            // Current
            int currentHealth = GetClientHealth(target);
            int maxHealth = GetEntProp(target, Prop_Data, "m_iMaxHealth");
            float healthMultiplier = float(currentHealth) / float(maxHealth);

            int color[4];
            color[0] = RoundToCeil(float(255) * (1.0 - healthMultiplier) );
            color[1] = RoundToCeil(float(255) * healthMultiplier);
            color[2] = 0;
            color[3] = 255;

            targetCurrent[0] = (healthMultiplier * (targetMax[0] - targetMin[0])) + targetMin[0];
            targetCurrent[1] = (healthMultiplier * (targetMax[1] - targetMin[1])) + targetMin[1];


            TE_SetupBeamPoints(targetMin, targetCurrent, beamSprite, 0, 0, 0, 0.1, 1.0, 1.0, 1, 0.0, color, 1000);
            TE_SendToClient (client);
            TE_SetupGlowSprite(targetMin, glowsprite, 0.1, 0.1, 128);
            TE_SendToClient (client);
            TE_SetupGlowSprite(targetMax, glowsprite, 0.1, 0.1, 128);
            TE_SendToClient (client);
        }

    }
}

stock bool isValidClient(int client, bool allowBot = false) {
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsClientSourceTV(client) || (!allowBot && IsFakeClient(client) ) ){
		return false;
	}
	return true;
}