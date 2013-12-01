class CoworkerAI extends UDKBot;

var Actor Destination;
var Actor actorTemp;
var(PathNodes) array<Pathnode> Waypoints;
var(CoworkerEventMarker) array<CoworkerEventMarker> Markers;
var(Object) name dest_tag;
var bool bTasking;
var int task_idx;
var int task_max;
var Rotator newRotation;
var int TASK_DEFAULT_WAIT;

//in-editor tagged nodes to walk to
var(Object) name task1;

simulated function PostBeginPlay() {
	local PathNode p;
	local CoworkerEventMarker m;
	foreach WorldInfo.AllActors(class'Pathnode',p)			//add the pathnodes to the array
	{
		if (InStr(p.Tag,"_Task")>0) { //limit pathnodes for looping in GetPathnodeByTag()
			Waypoints.AddItem(p);
		}
	}
	
	foreach Worldinfo.AllActors(class'CoworkerEventMarker',m)
	{
		Markers.AddItem(m);
	}
}

function CoworkerEventMarker GetMarkerByTag() {
	local int i;
	i=0;
	while (i < Markers.Length) {
		if (dest_tag == Markers[i].Tag) {
			return Markers[i];
		}
		i++;
	}
}

function Pathnode GetPathnodeByTag() {
	local int i;
	i=0;
	while (i < Waypoints.Length) {
		if (dest_tag == Waypoints[i].Tag) {
			return Waypoints[i];
		}
		i++;
	}
}
function HandleTask() {
//rotate
		dest_tag=name('CoworkerEventMarker_Task'$string(task_idx));
		Destination = GetMarkerByTag();
		Pawn.LockDesiredRotation(False);
		newRotation = Rotator(Destination.Location - Pawn.Location);
		Pawn.SetDesiredRotation(newRotation);
		Pawn.LockDesiredRotation(True, False);
}
function NextTask() {
	bTasking = false;
	task_idx++;
	if (task_idx>task_max) {
		task_idx = 1;
	}
	Pawn.LockDesiredRotation(False);
	//Pawn.SetMovementPhysics();
	GotoState('Tasking');
}

protected event ExecuteWhatToDoNext() {
  GotoState('Tasking');
}

auto state Init {
Begin:
	WaitForLanding();
	Pawn.SetMovementPhysics();
	NextTask();
	
	GotoState('Tasking');
}

state Tasking
{
Begin:
	
  //If we just began or we have reached the Destination
  //todo: Fix jumpfall on each node
	if (Destination != none) {
		//WaitForLanding();
		//Pawn.SetMovementPhysics();
	}
	//WaitForLanding();
  if(Destination == none || Pawn.ReachedDestination(Destination))
  {
	//bad redundant checking...
	if (Destination != none && Pawn.ReachedDestination(Destination)) {
		
		//run animation for task
		bTasking = true;
		HandleTask(); //run anims/dostuff like align to area of animation
		Destination = none;
		SetTimer(TASK_DEFAULT_WAIT,false,'NextTask'); //timer for animation to run
		//Worldinfo.Game.Broadcast(self,"Exec Task > for 10s");
		
	} else if (!bTasking) { //dont choose next location until animations are done
	
		dest_tag = name('PathNode_Task'$string(task_idx));
		Destination = GetPathnodeByTag();
		//Worldinfo.Game.Broadcast(self,dest_tag);
		if (Destination == none) {
			//Worldinfo.Game.Broadcast(self,"Next Task > not found");
		} else {
			//Worldinfo.Game.Broadcast(self,"Next Task > node");
			//Worldinfo.Game.Broadcast(self,Destination.Name);
		}
	}
  }

  if (Destination != none) {
	actorTemp = FindPathToward(Destination);
	if (actorTemp == none) {
		MoveToward(Destination);
		//Worldinfo.Game.Broadcast(self,"FindPathToward failed, trying directly");
	} else {
		MoveToward(FindPathToward(Destination),FindPathToward(Destination)); //, FindPathToward(Destination));
	}
  }
  sleep(0.1);
  GotoState('Tasking');
}

DefaultProperties
{
	TASK_DEFAULT_WAIT=4
	task1="PathNode_Task1"
	dest_tag=task1
	task_idx=0
	task_max=3
	bTasking=false;
}
