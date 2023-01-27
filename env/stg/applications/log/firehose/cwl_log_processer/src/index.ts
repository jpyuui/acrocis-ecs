import type {
  FirehoseTransformationEvent,
  FirehoseTransformationEventRecord,
  FirehoseRecordTransformationStatus,
} from "./../node_modules/@types/aws-lambda/trigger/kinesis-firehose-transformation.d";
import type {
  CloudWatchLogsDecodedData,
  CloudWatchLogsLogEvent,
} from "./../node_modules/@types/aws-lambda/trigger/cloudwatch-logs.d";
import type { Callback, Context } from "aws-lambda";
import zlib from "node:zlib";

const statusOk: FirehoseRecordTransformationStatus = "Ok";
const statusFailed: FirehoseRecordTransformationStatus = "ProcessingFailed";
const statusDropped: FirehoseRecordTransformationStatus = "Dropped";
const MAXIMUM_RECORD_SIZE = 6000000;

const transformLogEvent = (log: CloudWatchLogsLogEvent) => {
  // logのデータ整形はここでやる
  return `${log}\n`;
};

export const handler = async (
  event: FirehoseTransformationEvent,
  _: Context,
  __: Callback
) => {
  const output = event.records.map((r: FirehoseTransformationEventRecord) => {
    const decoded = Buffer.from(r.data, "base64");
    let decompressed;
    try {
      // CWLサブスクリプションフィルターのデータはgzip圧縮されてるので解凍する
      decompressed = zlib.gunzipSync(decoded);
    } catch (e) {
      console.error(e);
      return {
        recordId: r.recordId,
        result: statusFailed,
      };
    }

    const data: CloudWatchLogsDecodedData = JSON.parse(
      decompressed.toString("utf-8")
    );
    if (data.messageType === "CONTROL_MESSAGE") {
      console.log("record dropped", data);
      return {
        recordId: r.recordId,
        result: statusDropped,
      };
    }
    if (data.messageType !== "DATA_MESSAGE") {
      console.log("record processing failed", data);
      return {
        recordId: r.recordId,
        result: statusFailed,
      };
    }

    const transformedData = data.logEvents.map(transformLogEvent);
    const payload = transformedData.reduce((a, v) => a + v, "");
    const encoded = Buffer.from(payload).toString("base64");
    if (encoded.length <= MAXIMUM_RECORD_SIZE) {
      console.log("record processing success", data);
      return {
        recordId: r.recordId,
        result: statusOk,
        data: encoded,
      };
    } else {
      // 各レコードサイズが6MB制限を超える場合、"ProcessingFailed"とする。
      console.error(
        "record processing failed, exceed maximum record size",
        data
      );
      return {
        recordId: r.recordId,
        result: statusFailed,
      };
    }
  });

  return { records: output };
};
