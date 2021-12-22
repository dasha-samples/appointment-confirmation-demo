const dasha = require("@dasha.ai/sdk");
const fs = require("fs");

async function main() {
  const app = await dasha.deploy("./app");

  app.ttsDispatcher = () => "Default";


  app.setExternal("check_availability", (args, conv) => {
    // Implement how to check availability in yoor database
    // Now availability is random
    return Math.random() > 0.5;
  });

  const days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  // Select random day of appointment
  // You should define it with the database
  let day = days[Math.floor(Math.random() * days.length)];

  const conv = app.createConversation({
    phone: process.argv[2],
    day_of_week: day,
  });

  await app.start();
  
  conv.audio.tts = "dasha";

  if (conv.input.phone === "chat") {
    await dasha.chat.createConsoleChat(conv);
  } else {
    conv.on("transcription", console.log);
  }

  const logFile = await fs.promises.open("./log.txt", "w");
  await logFile.appendFile("#".repeat(100) + "\n");

  conv.on("transcription", async (entry) => {
    await logFile.appendFile(`${entry.speaker}: ${entry.text}\n`);
  });

  conv.on("debugLog", async (event) => {
    if (event?.msg?.msgId === "RecognizedSpeechMessage") {
      const logEntry = event?.msg?.results[0]?.facts;
      await logFile.appendFile(JSON.stringify(logEntry, undefined, 2) + "\n");
    }
  });

  const result = await conv.execute({
    channel: conv.input.phone === "chat" ? "text" : "audio",
  });
  // Scedule new call on day_recall
  console.log(result.output.day_recall);
  // Rescedule appointment on new_day in yoor database
  console.log(result.output.new_day);
  await app.stop();
  app.dispose();
  await logFile.close();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
