import type {
  FirehoseTransformationEvent,
  FirehoseTransformationEventRecord,
  FirehoseRecordTransformationStatus,
} from "./../node_modules/@types/aws-lambda/trigger/kinesis-firehose-transformation.d";
import type { Callback, Context } from "aws-lambda";

const statusOk: FirehoseRecordTransformationStatus = "Ok";
const statusFailed: FirehoseRecordTransformationStatus = "ProcessingFailed";
const statusDropped: FirehoseRecordTransformationStatus = "Dropped";
const MAXIMUM_RECORD_SIZE = 6000000;

const transformLog = (log: any) => {
  // logのデータ整形はここでやる
  return JSON.stringify(log);
};

export const handler = async (
  event: FirehoseTransformationEvent,
  _: Context,
  __: Callback
) => {
  const output = event.records.map((r: FirehoseTransformationEventRecord) => {
    const decoded = Buffer.from(r.data, "base64").toString("utf-8");
    const data = JSON.parse(decoded);

    let parsedLog;
    try {
      parsedLog = JSON.parse(data.log);
    } catch (e) {
      console.log("record parse error", data.log);
      return {
        recordId: r.recordId,
        result: statusDropped,
      };
    }


    console.log("parsedLog", parsedLog);



    const transformedLog = transformLog(parsedLog);
    const encoded = Buffer.from(transformedLog).toString("base64");

    if (encoded.length <= MAXIMUM_RECORD_SIZE) {
      console.log("record processing success", transformedLog);
      return {
        recordId: r.recordId,
        result: statusOk,
        data: encoded,
      };
    } else {
      // 各レコードサイズが6MB制限を超える場合、"ProcessingFailed"とする。
      console.error(
        "record processing failed, exceed maximum record size",
        transformedLog
      );
      return {
        recordId: r.recordId,
        result: statusFailed,
      };
    }
  });

  return { records: output };
};
