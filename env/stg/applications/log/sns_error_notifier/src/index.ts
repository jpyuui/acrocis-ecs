import type { PublishCommandInput } from "./../node_modules/@aws-sdk/client-sns/dist-types/commands/PublishCommand.d";
import type {
  CloudWatchLogsDecodedData,
  CloudWatchLogsEvent,
  CloudWatchLogsLogEvent,
} from "./../node_modules/@types/aws-lambda/trigger/cloudwatch-logs.d";
import { SNSClient } from "@aws-sdk/client-sns";
import { PublishCommand } from "@aws-sdk/client-sns";
import type { Callback, Context } from "aws-lambda";
import zlib from "node:zlib";

// Env
const REGION = process.env.REGION!;
const SERVICE_NAME = process.env.SERVICE_NAME!;
const SERVICE_ENV = process.env.SERVICE_ENV!;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN!;
const SUBJECT = process.env.SUBJECT!;

const transformLog = (data: CloudWatchLogsDecodedData): string => {
  const logData = data.logEvents.map(
    (l: CloudWatchLogsLogEvent) => `${l.message}\n`
  );
  const log = JSON.stringify(logData, null, 2);

  return log;
};

interface emailParams {
  serviceName: string;
  serviceEnv: string;
  log: string;
}

const genPublishData = (
  snsTopicArn: string,
  subject: string,
  params: emailParams
): PublishCommandInput => {
  return {
    TopicArn: snsTopicArn,
    Subject: subject,
    Message: `
  エラーが発生しました。\n
  当該サービス: ${params.serviceName}\n
  当該環境: ${params.serviceEnv}\n
  ログ:\n
  ${params.log}
  `,
  };
};

const matchExcludeStrRules = (logStr: string): boolean => {
  // TODO: 根本解決
  // Subscriberで発生中のwarning解決まで明示的に無視する
  if (logStr.indexOf("SPELL_CHECKERS") === -1) {
    return true;
  }
  return false;
};

export const handler = async (
  event: CloudWatchLogsEvent,
  _: Context,
  __: Callback
) => {
  const decoded = Buffer.from(event.awslogs.data, "base64");
  const decompressed = zlib.unzipSync(decoded);
  const data: CloudWatchLogsDecodedData = JSON.parse(
    decompressed.toString("utf8")
  );
  const transformedLog = transformLog(data);
  const snsPublishData = genPublishData(SNS_TOPIC_ARN, SUBJECT, {
    serviceName: SERVICE_NAME,
    serviceEnv: SERVICE_ENV,
    log: transformedLog,
  });

  const snsClient = new SNSClient({ region: REGION });
  try {
    if (matchExcludeStrRules(transformedLog)) {
      const data = await snsClient.send(new PublishCommand(snsPublishData));
      console.log("Success", data);
    } else {
      console.log("Pass");
    }
  } catch (err: any) {
    console.error("Error", err.stack);
  }
};
