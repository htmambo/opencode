import type { Component } from "solid-js"
import type { QuestionRequest } from "@opencode-ai/sdk/v2"
import { SessionQuestionDock } from "@/pages/session/composer/session-question-dock"

export const QuestionDock: Component<{ request: QuestionRequest }> = (props) => {
  return <SessionQuestionDock request={props.request} onSubmit={() => {}} />
}
