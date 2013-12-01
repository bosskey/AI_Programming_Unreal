class FinalGuardAI extends UDKBot;
var Pawn GuardTarget;
var Pawn EnemyTarget; 
var Vector NavGoalLocation;
var Vector NextLocationToGoal;

var int tDist;
var float tDot;

var int GUARD_ENEMYRANGE_DEFEND;


function BeginState (name PreviousStateName){
	NavGoalLocation=Pawn.Location;
}

function SetAimRot(Pawn p,Object.Vector aim) {
    local Rotator final_rot;
	final_rot = Rotator(Normal(aim)); //Look straight at aim
    p.SetViewRotation(final_rot);
}

event PostBeginPlay() {
	local Pawn A;
	ForEach WorldInfo.AllPawns(class'Pawn',A) {
		if (A.IsPlayerPawn()) {
			GuardTarget=A;
		}
		else if (A!=Pawn) {
			EnemyTarget=A;
		}
	}
}

event SeePlayer(Pawn SeenPlayer)
{
	if (SeenPlayer.IsAliveAndWell() && SeenPlayer.IsPlayerPawn()) {
		GuardTarget=SeenPlayer;
	}
}

auto state Guard {
	Begin:
		tDist=VSize(GuardTarget.Location-Pawn.Location);
		if (EnemyTarget.IsAliveAndWell() && VSize(EnemyTarget.Location-GuardTarget.Location)<GUARD_ENEMYRANGE_DEFEND) {
			Worldinfo.Game.Broadcast(self,"G:Guard->Defend: Proximity of enemy");
			GotoState('Defend');
		}

		MoveToward(GuardTarget); //follow guarding target

	//SetAimRot(Pawn,GuardTarget.Location-Pawn.Location);
	//Pawn.SetDesiredRotation(Rotator(Normal(GuardTarget.Location-Pawn.Location)),true);
	Sleep(0.1);
	goto('Begin');
}

state Defend {
Begin:
	if (EnemyTarget.IsAliveAndWell()) {
			Pawn.SetDesiredRotation(Rotator(Normal(EnemyTarget.Location-Pawn.Location)));
			Pawn.StartFire(0);
		
	}
	else if (EnemyTarget.Health<10) {
		Worldinfo.Game.Broadcast(self,"G:Defend->Guard: Enemy died");
		Pawn.StopFire(0);
		GotoState('Guard');
	}
	MoveToward(EnemyTarget);
Sleep(0.1);
goto('Begin');
}

DefaultProperties
{
//All capitals to me represents something not to change the value of but to read-only *Rule of programming (for me) that works in all languages, helps cross language compatibility and mental-process

GUARD_ENEMYRANGE_DEFEND=450
}