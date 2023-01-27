import type { SNSEvent } from "./../node_modules/@types/aws-lambda/trigger/sns.d";
import type { PublishCommandInput } from "./../node_modules/@aws-sdk/client-sns/dist-types/commands/PublishCommand.d";
import { SNSClient } from "@aws-sdk/client-sns";
import { PublishCommand } from "@aws-sdk/client-sns";
import type { Callback, Context } from "aws-lambda";

// Env
const REGION = process.env.REGION!;
const SERVICE_NAME = process.env.SERVICE_NAME!;
const SERVICE_ENV = process.env.SERVICE_ENV!;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN!;
const SUBJECT = process.env.SUBJECT!;

interface emailParams {
  serviceName: string;
  serviceEnv: string;
  message: string;
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
  CodePipelineからの通知。\n
  当該サービス: ${params.serviceName}\n
  当該環境: ${params.serviceEnv}\n
  結果: ${params.message}
  `,
  };
};

export const handler = async (event: SNSEvent, _: Context, __: Callback) => {
  const message = JSON.parse(event.Records[0].Sns.Message);
  console.log(message, "Receive Message");

  const pipelineStatus = message.detail.state;
  const snsPublishData = genPublishData(SNS_TOPIC_ARN, SUBJECT, {
    serviceName: SERVICE_NAME,
    serviceEnv: SERVICE_ENV,
    message: pipelineStatus,
  });

  const snsClient = new SNSClient({ region: REGION });
  try {
    const data = await snsClient.send(new PublishCommand(snsPublishData));
    console.log("Success", data);
  } catch (err: any) {
    console.error("Error", err.stack);
  }
};
