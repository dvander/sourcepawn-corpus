#include <sourcemod>


public OnPluginStart() 
{
	RegAdminCmd("sm_ejemplo", EjecutarCFG, ADMFLAG_ROOT);  // comando sm_ejemplo = !ejemplo en chat - permisos de admin: root
}


public Action:EjecutarCFG(client, args) 
{
	ServerCommand("exec ejemplo.cfg"); // comando que se ejecuta "exec ejemplo"
}

   