#============
# Builder
#============
FROM node:16-alpine AS builder

WORKDIR /usr/app

COPY package*.json ./
COPY tsconfig.json ./
COPY src ./src

RUN npm i --only-production
RUN npm run build


#============
# Production
#============
FROM public.ecr.aws/lambda/nodejs:16 as Production
ENV NODE_ENV production

COPY --from=builder /usr/app/build ${LAMBDA_TASK_ROOT}
COPY --from=builder /usr/app/node_modules ${LAMBDA_TASK_ROOT}

CMD [ "lambda.handler" ]