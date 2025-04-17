let previousTicket = 0;
let mostRecentRunTicket = 0;
let currentAction: Promise<void> = Promise.resolve(undefined);

export async function schedule(action: () => Promise<void>) {
  const previous = previousTicket;
  const myTicket = previous + 1;
  previousTicket = myTicket;
  console.log(`Scheduled action ${myTicket}`);
  while (true) {
    await currentAction;
    if (mostRecentRunTicket == previous) break; // Our turn!
  }
  console.log(
    `Running action ${myTicket} (${previousTicket - myTicket} waiting)`,
  );
  currentAction = action();
  try {
    await currentAction;
  } catch (error) {
    console.error(`Action failed: ${error}`);
  }
  mostRecentRunTicket = myTicket;
}
