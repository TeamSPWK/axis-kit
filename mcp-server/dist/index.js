// src/index.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { fileURLToPath } from "url";
import path4 from "path";

// src/tools/get-rules.ts
import { z } from "zod";
import fs from "fs/promises";
import path from "path";
function registerGetRules(server2, novaRoot) {
  server2.registerTool(
    "get_rules",
    {
      title: "Nova \uADDC\uCE59 \uC870\uD68C",
      description: "Nova \uD488\uC9C8 \uAC8C\uC774\uD2B8 \uADDC\uCE59 \uC804\uBB38\uC744 \uBC18\uD658\uD569\uB2C8\uB2E4. section\uC744 \uC9C0\uC815\uD558\uBA74 \uD574\uB2F9 \uC139\uC158(\xA71~\xA79)\uB9CC \uBC18\uD658\uD569\uB2C8\uB2E4.",
      inputSchema: z.object({
        section: z.string().regex(/^\d+$/, "\uC139\uC158 \uBC88\uD638\uB294 \uC22B\uC790\uB9CC \uD5C8\uC6A9\uB429\uB2C8\uB2E4").optional().describe(
          "\uD2B9\uC815 \uC139\uC158 \uBC88\uD638 (\uC608: '1', '2'). \uBBF8\uC9C0\uC815 \uC2DC \uC804\uCCB4 \uADDC\uCE59 \uBC18\uD658"
        )
      })
    },
    async ({ section }) => {
      const rulesPath = path.join(novaRoot, "docs", "nova-rules.md");
      let content;
      try {
        content = await fs.readFile(rulesPath, "utf-8");
      } catch {
        return {
          content: [
            {
              type: "text",
              text: "\uD30C\uC77C\uC744 \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4: docs/nova-rules.md"
            }
          ]
        };
      }
      if (!section) {
        return { content: [{ type: "text", text: content }] };
      }
      const sectionPattern = new RegExp(
        `(## \xA7${section}\\..+?)(?=## \xA7|$)`,
        "s"
      );
      const match = content.match(sectionPattern);
      if (!match) {
        return {
          content: [
            {
              type: "text",
              text: `\uC139\uC158 \xA7${section}\uC744 \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4. \uC720\uD6A8\uD55C \uC139\uC158 \uBC88\uD638\uB97C \uD655\uC778\uD558\uC138\uC694.`
            }
          ]
        };
      }
      return { content: [{ type: "text", text: match[1].trim() }] };
    }
  );
}

// src/tools/get-commands.ts
import fs2 from "fs/promises";
import path2 from "path";
async function extractDescription(filePath) {
  try {
    const content = await fs2.readFile(filePath, "utf-8");
    const lines = content.split("\n");
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.startsWith("description:")) {
        return trimmed.replace("description:", "").trim().replace(/^["']|["']$/g, "");
      }
    }
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.startsWith("#")) {
        return trimmed.replace(/^#+\s*/, "");
      }
      if (trimmed.length > 0 && !trimmed.startsWith("---")) {
        return trimmed.length > 100 ? trimmed.slice(0, 100) + "..." : trimmed;
      }
    }
    return "\uC124\uBA85 \uC5C6\uC74C";
  } catch {
    return "\uD30C\uC77C \uC77D\uAE30 \uC2E4\uD328";
  }
}
async function resolveCommandsDir(novaRoot) {
  const candidates = [
    path2.join(novaRoot, ".claude", "commands"),
    path2.join(novaRoot, "commands")
  ];
  for (const candidate of candidates) {
    try {
      await fs2.access(candidate);
      return candidate;
    } catch {
    }
  }
  return null;
}
function registerGetCommands(server2, novaRoot) {
  server2.registerTool(
    "get_commands",
    {
      title: "Nova \uCEE4\uB9E8\uB4DC \uBAA9\uB85D \uC870\uD68C",
      description: ".claude/commands/ \uB514\uB809\uD1A0\uB9AC\uC758 \uBAA8\uB4E0 \uC2AC\uB798\uC2DC \uCEE4\uB9E8\uB4DC \uBAA9\uB85D\uACFC \uC124\uBA85\uC744 \uBC18\uD658\uD569\uB2C8\uB2E4.",
      inputSchema: void 0
    },
    async () => {
      const commandsDir = await resolveCommandsDir(novaRoot);
      if (!commandsDir) {
        return {
          content: [
            {
              type: "text",
              text: "\uD30C\uC77C\uC744 \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4: .claude/commands/ \uB610\uB294 commands/ \uB514\uB809\uD1A0\uB9AC\uAC00 \uC874\uC7AC\uD558\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4."
            }
          ]
        };
      }
      let files;
      try {
        const entries = await fs2.readdir(commandsDir);
        files = entries.filter((f) => f.endsWith(".md")).sort();
      } catch {
        return {
          content: [
            {
              type: "text",
              text: `\uD30C\uC77C\uC744 \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4: ${commandsDir} \uB514\uB809\uD1A0\uB9AC\uB97C \uC77D\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.`
            }
          ]
        };
      }
      const commands = await Promise.all(
        files.map(async (file) => {
          const name = file.replace(".md", "");
          const description = await extractDescription(
            path2.join(commandsDir, file)
          );
          return { name: `/${name}`, description };
        })
      );
      const lines = [
        "# Nova \uC2AC\uB798\uC2DC \uCEE4\uB9E8\uB4DC \uBAA9\uB85D\n",
        ...commands.map((c) => `**${c.name}** \u2014 ${c.description}`)
      ];
      return {
        content: [{ type: "text", text: lines.join("\n") }]
      };
    }
  );
}

// src/tools/get-state.ts
import { z as z2 } from "zod";
import fs3 from "fs/promises";
import path3 from "path";
function registerGetState(server2) {
  server2.registerTool(
    "get_state",
    {
      title: "NOVA-STATE.md \uC77D\uAE30",
      description: "\uC9C0\uC815\uB41C \uD504\uB85C\uC81D\uD2B8 \uACBD\uB85C\uC758 NOVA-STATE.md \uD30C\uC77C\uC744 \uC77D\uC5B4 \uBC18\uD658\uD569\uB2C8\uB2E4.",
      inputSchema: z2.object({
        project_path: z2.string().optional().describe(
          "NOVA-STATE.md\uAC00 \uC704\uCE58\uD55C \uD504\uB85C\uC81D\uD2B8 \uB8E8\uD2B8 \uACBD\uB85C. \uBBF8\uC9C0\uC815 \uC2DC \uD604\uC7AC \uB514\uB809\uD1A0\uB9AC(process.cwd())"
        )
      })
    },
    async ({ project_path }) => {
      const targetDir = project_path ?? process.cwd();
      const statePath = path3.join(targetDir, "NOVA-STATE.md");
      try {
        const content = await fs3.readFile(statePath, "utf-8");
        return {
          content: [
            {
              type: "text",
              text: `# NOVA-STATE.md (${targetDir})

${content}`
            }
          ]
        };
      } catch {
        return {
          content: [
            {
              type: "text",
              text: `\uD30C\uC77C\uC744 \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4: ${statePath}

NOVA-STATE.md\uAC00 \uC874\uC7AC\uD558\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4. /init \uCEE4\uB9E8\uB4DC\uB85C \uCD08\uAE30\uD654\uD558\uC138\uC694.`
            }
          ]
        };
      }
    }
  );
}

// src/tools/create-plan.ts
import { z as z3 } from "zod";
function buildPlanTemplate(topic, context) {
  const now = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
  return `# Plan: ${topic}

> \uC791\uC131\uC77C: ${now}
> \uD504\uB808\uC784\uC6CC\uD06C: CPS (Context \u2192 Problem \u2192 Solution)

---

## Context

> \uC65C \uC774 \uC791\uC5C5\uC774 \uD544\uC694\uD55C\uAC00? \uBC30\uACBD\uACFC \uD604\uC7AC \uC0C1\uD0DC\uB97C \uAE30\uC220\uD55C\uB2E4.

${context ? context : "<!-- \uBC30\uACBD, \uD604\uC7AC \uC0C1\uD0DC, \uC791\uC5C5 \uB3D9\uAE30\uB97C \uC5EC\uAE30\uC5D0 \uAE30\uC220\uD558\uC138\uC694 -->"}

### \uD604\uC7AC \uC0C1\uD0DC
- [ ] \uD604\uC7AC \uC2DC\uC2A4\uD15C/\uAE30\uB2A5\uC758 \uC0C1\uD0DC

### \uC791\uC5C5 \uB3D9\uAE30
- [ ] \uC774 \uC791\uC5C5\uC744 \uC9C0\uAE08 \uD574\uC57C \uD558\uB294 \uC774\uC720

---

## Problem

> \uAD6C\uCCB4\uC801\uC73C\uB85C \uBB34\uC5C7\uC774 \uBB38\uC81C\uC778\uAC00? MECE(\uC0C1\uD638 \uBC30\uD0C0\uC801, \uC804\uCCB4 \uD3EC\uAD04)\uB85C \uBD84\uD574\uD55C\uB2E4.

### \uD575\uC2EC \uBB38\uC81C
- [ ] \uBB38\uC81C 1
- [ ] \uBB38\uC81C 2

### \uC81C\uC57D \uC870\uAC74
- \uAE30\uC220\uC801 \uC81C\uC57D:
- \uBE44\uC988\uB2C8\uC2A4 \uC81C\uC57D:
- \uC2DC\uAC04 \uC81C\uC57D:

### \uBE44\uAE30\uB2A5 \uC694\uAD6C\uC0AC\uD56D
- \uC778\uC99D/\uBCF4\uC548:
- \uC131\uB2A5:
- \uC678\uBD80 \uC5F0\uB3D9:

---

## Solution

> \uC5B4\uB5BB\uAC8C \uD574\uACB0\uD558\uB294\uAC00? \uD2B8\uB808\uC774\uB4DC\uC624\uD504\uC640 \uACB0\uC815 \uADFC\uAC70\uB97C \uD3EC\uD568\uD55C\uB2E4.

### \uC811\uADFC \uBC29\uC2DD
<!-- \uC120\uD0DD\uD55C \uD574\uACB0\uCC45\uACFC \uADF8 \uC774\uC720 -->

### \uB300\uC548 \uAC80\uD1A0
| \uB300\uC548 | \uC7A5\uC810 | \uB2E8\uC810 | \uACB0\uC815 |
|------|------|------|------|
| \uC548 A |  |  | \uAE30\uAC01 |
| \uC548 B |  |  | **\uCC44\uD0DD** |

### \uAD6C\uD604 \uACC4\uD68D
1. \uB2E8\uACC4 1:
2. \uB2E8\uACC4 2:
3. \uB2E8\uACC4 3:

### \uBCF5\uC7A1\uB3C4 \uD310\uC815
- \uC218\uC815 \uD30C\uC77C \uC608\uC0C1: __\uAC1C
- \uBCF5\uC7A1\uB3C4: \u2610 \uAC04\uB2E8 / \u2610 \uBCF4\uD1B5 / \u2610 \uBCF5\uC7A1
- \uACE0\uC704\uD5D8 \uC601\uC5ED(\uC778\uC99D/DB/\uACB0\uC81C): \u2610 \uD574\uB2F9 / \u2610 \uBBF8\uD574\uB2F9

### \uAC80\uC99D \uACC4\uD68D
- [ ] \uAE30\uB2A5 \uD14C\uC2A4\uD2B8:
- [ ] \uC5E3\uC9C0 \uCF00\uC774\uC2A4:
- [ ] \uC131\uB2A5 \uD655\uC778:

---

## \uC2B9\uC778

- [ ] \uACC4\uD68D \uAC80\uD1A0 \uC644\uB8CC
- [ ] \uAD6C\uD604 \uCC29\uC218 \uC2B9\uC778
`;
}
function registerCreatePlan(server2) {
  server2.registerTool(
    "create_plan",
    {
      title: "CPS Plan \uC0DD\uC131",
      description: "CPS(Context \u2192 Problem \u2192 Solution) \uD504\uB808\uC784\uC6CC\uD06C \uAE30\uBC18\uC758 Plan \uBB38\uC11C \uCD08\uC548\uC744 \uC0DD\uC131\uD569\uB2C8\uB2E4.",
      inputSchema: z3.object({
        topic: z3.string().describe("Plan\uC758 \uC8FC\uC81C \uB610\uB294 \uAE30\uB2A5\uBA85"),
        context: z3.string().optional().describe("Context \uC139\uC158\uC5D0 \uBBF8\uB9AC \uCC44\uC6B8 \uBC30\uACBD \uC815\uBCF4 (\uC120\uD0DD)")
      })
    },
    async ({ topic, context }) => {
      const planText = buildPlanTemplate(topic, context);
      return {
        content: [{ type: "text", text: planText }]
      };
    }
  );
}

// src/tools/orchestrate.ts
import { z as z4 } from "zod";
function buildOrchestrationGuide(task, complexity) {
  const guides = {
    simple: `# \uC624\uCF00\uC2A4\uD2B8\uB808\uC774\uC158 \uAC00\uC774\uB4DC: \uAC04\uB2E8 \uC791\uC5C5

## \uD0DC\uC2A4\uD06C
${task}

## \uD310\uC815: \uB2E8\uC77C \uC5D0\uC774\uC804\uD2B8 (\uC9C1\uC811 \uC2E4\uD589)

**\uAE30\uC900**: \uBC84\uADF8 \uC218\uC815, 1~2 \uD30C\uC77C \uC218\uC815, \uBA85\uD655\uD55C \uBCC0\uACBD

### \uC2E4\uD589 \uC808\uCC28
1. \uAD6C\uD604 (Generator)
2. \uB3C5\uB9BD \uAC80\uC99D (Evaluator \uC11C\uBE0C\uC5D0\uC774\uC804\uD2B8)
3. \uAC80\uC99D PASS \u2192 \uCEE4\uBC0B

### Evaluator \uD504\uB86C\uD504\uD2B8 \uD15C\uD50C\uB9BF
\`\`\`
\uB2F9\uC2E0\uC740 \uCF54\uB4DC \uAC80\uC99D \uC804\uBB38\uAC00\uC785\uB2C8\uB2E4. \uC801\uB300\uC801 \uC790\uC138\uB85C \uB2E4\uC74C\uC744 \uAC80\uD1A0\uD558\uC138\uC694:

\uD0DC\uC2A4\uD06C: ${task}

\uAC80\uC99D \uD56D\uBAA9:
- [ ] \uAE30\uB2A5\uC774 \uC694\uAD6C\uC0AC\uD56D\uB300\uB85C \uB3D9\uC791\uD558\uB294\uAC00?
- [ ] \uC5E3\uC9C0 \uCF00\uC774\uC2A4(\uBE48 \uAC12, 0, \uC74C\uC218, \uBE48 \uBC30\uC5F4)\uC5D0\uC11C \uD06C\uB798\uC2DC\uD558\uC9C0 \uC54A\uB294\uAC00?
- [ ] \uAE30\uC874 \uB3D9\uC791\uC774 \uC190\uC0C1\uB418\uC9C0 \uC54A\uC558\uB294\uAC00?
- [ ] \uBD88\uD544\uC694\uD55C \uBCC0\uACBD\uC774 \uD3EC\uD568\uB418\uC9C0 \uC54A\uC558\uB294\uAC00?

PASS / FAIL \uD310\uC815\uACFC \uC774\uC720\uB97C \uBA85\uC2DC\uD558\uC138\uC694.
\`\`\`
`,
    medium: `# \uC624\uCF00\uC2A4\uD2B8\uB808\uC774\uC158 \uAC00\uC774\uB4DC: \uBCF4\uD1B5 \uC791\uC5C5

## \uD0DC\uC2A4\uD06C
${task}

## \uD310\uC815: Generator + Evaluator \uBD84\uB9AC

**\uAE30\uC900**: 3~7 \uD30C\uC77C \uC218\uC815, \uC0C8 \uAE30\uB2A5 \uCD94\uAC00

### \uC5D0\uC774\uC804\uD2B8 \uD3B8\uC131
| \uC5ED\uD560 | \uB2F4\uB2F9 | \uC2E4\uD589 \uBC29\uC2DD |
|------|------|----------|
| **Orchestrator** | \uACC4\uD68D \uC218\uB9BD, \uCD5C\uC885 \uD310\uB2E8 | \uBA54\uC778 |
| **Generator** | \uAD6C\uD604 | \uC11C\uBE0C\uC5D0\uC774\uC804\uD2B8 |
| **Evaluator** | \uB3C5\uB9BD \uAC80\uC99D | \uC11C\uBE0C\uC5D0\uC774\uC804\uD2B8 (Generator\uC640 \uB3C5\uB9BD) |

### \uC2E4\uD589 \uC808\uCC28
1. Orchestrator: Plan \uC791\uC131 + \uC2B9\uC778
2. Generator \uC11C\uBE0C\uC5D0\uC774\uC804\uD2B8: \uAD6C\uD604
3. Evaluator \uC11C\uBE0C\uC5D0\uC774\uC804\uD2B8: \uB3C5\uB9BD \uAC80\uC99D (Generator \uCEE8\uD14D\uC2A4\uD2B8 \uBBF8\uACF5\uC720)
4. Evaluator PASS \u2192 Orchestrator \uCD5C\uC885 \uD655\uC778 \u2192 \uCEE4\uBC0B

### Generator \uD504\uB86C\uD504\uD2B8 \uD15C\uD50C\uB9BF
\`\`\`
\uB2F9\uC2E0\uC740 \uAD6C\uD604 \uC804\uBB38\uAC00\uC785\uB2C8\uB2E4.

\uD0DC\uC2A4\uD06C: ${task}

\uB2E4\uC74C \uC21C\uC11C\uB85C \uC9C4\uD589\uD558\uC138\uC694:
1. \uC601\uD5A5 \uD30C\uC77C \uBAA9\uB85D \uD655\uC778
2. \uCD5C\uC18C \uBCC0\uACBD \uC6D0\uCE59\uC73C\uB85C \uAD6C\uD604
3. tsc/lint \uD1B5\uACFC \uD655\uC778
4. \uAD6C\uD604 \uC644\uB8CC \uBCF4\uACE0 (\uBCC0\uACBD \uD30C\uC77C \uBAA9\uB85D + \uBCC0\uACBD \uC0AC\uC720 \uD3EC\uD568)
\`\`\`

### Evaluator \uD504\uB86C\uD504\uD2B8 \uD15C\uD50C\uB9BF
\`\`\`
\uB2F9\uC2E0\uC740 \uCF54\uB4DC \uAC80\uC99D \uC804\uBB38\uAC00\uC785\uB2C8\uB2E4. \uC801\uB300\uC801 \uC790\uC138\uB85C \uAC80\uD1A0\uD558\uC138\uC694.
Generator\uC758 \uAD6C\uD604 \uC758\uB3C4\uB97C \uC54C\uACE0 \uC788\uB354\uB77C\uB3C4 \uB3C5\uB9BD\uC801\uC73C\uB85C \uD310\uB2E8\uD558\uC138\uC694.

\uD0DC\uC2A4\uD06C: ${task}

\uAC80\uC99D \uD56D\uBAA9:
- [ ] \uAE30\uB2A5 \uC694\uAD6C\uC0AC\uD56D \uCDA9\uC871
- [ ] \uC5E3\uC9C0 \uCF00\uC774\uC2A4 \uC548\uC804\uC131
- [ ] \uAE30\uC874 \uAE30\uB2A5 \uD68C\uADC0 \uC5C6\uC74C
- [ ] \uBD88\uD544\uC694\uD55C \uCD94\uC0C1\uD654/\uCF54\uB4DC \uC5C6\uC74C
- [ ] \uC5D0\uB7EC \uD578\uB4E4\uB9C1 \uC801\uC808\uC131
- [ ] \uD14C\uC2A4\uD2B8 \uC6A9\uC774\uC131

PASS / NEEDS WORK / FAIL \uD310\uC815 + \uADFC\uAC70 + \uC218\uC815 \uC81C\uC548
\`\`\`
`,
    complex: `# \uC624\uCF00\uC2A4\uD2B8\uB808\uC774\uC158 \uAC00\uC774\uB4DC: \uBCF5\uC7A1 \uC791\uC5C5

## \uD0DC\uC2A4\uD06C
${task}

## \uD310\uC815: \uC2A4\uD504\uB9B0\uD2B8 \uBD84\uD560 + \uC804\uBB38 \uC5D0\uC774\uC804\uD2B8 \uD300

**\uAE30\uC900**: 8+ \uD30C\uC77C, \uB2E4\uC911 \uBAA8\uB4C8, \uC678\uBD80 \uC758\uC874\uC131, \uACE0\uC704\uD5D8 \uC601\uC5ED

### \uC5D0\uC774\uC804\uD2B8 \uD300 \uD3B8\uC131
| \uC5ED\uD560 | \uB2F4\uB2F9 | \uC2E4\uD589 \uBC29\uC2DD |
|------|------|----------|
| **Orchestrator** | \uC2A4\uD504\uB9B0\uD2B8 \uAD00\uB9AC, \uAC8C\uC774\uD2B8 \uD1B5\uACFC \uACB0\uC815 | \uBA54\uC778 |
| **Architect** | \uC124\uACC4 \uAC80\uD1A0 \uBC0F \uD2B8\uB808\uC774\uB4DC\uC624\uD504 \uBD84\uC11D | \uC11C\uBE0C\uC5D0\uC774\uC804\uD2B8 |
| **Generator** | \uC2A4\uD504\uB9B0\uD2B8\uBCC4 \uAD6C\uD604 | \uC11C\uBE0C\uC5D0\uC774\uC804\uD2B8 |
| **Evaluator** | \uAC01 \uC2A4\uD504\uB9B0\uD2B8 \uB3C5\uB9BD \uAC80\uC99D | \uC11C\uBE0C\uC5D0\uC774\uC804\uD2B8 |
| **Integrator** | \uC804\uCCB4 \uD1B5\uD569 + \uD68C\uADC0 \uD14C\uC2A4\uD2B8 | \uC11C\uBE0C\uC5D0\uC774\uC804\uD2B8 |

### \uC2E4\uD589 \uC808\uCC28
\`\`\`
Phase 1: \uC124\uACC4
  Orchestrator \u2192 Architect: Design \uBB38\uC11C \uC791\uC131 \uC694\uCCAD
  Architect \u2192 Orchestrator: \uD2B8\uB808\uC774\uB4DC\uC624\uD504 \uD3EC\uD568 \uC124\uACC4 \uC81C\uCD9C
  Orchestrator: \uC124\uACC4 \uC2B9\uC778

Phase 2: \uC2A4\uD504\uB9B0\uD2B8 \uC2E4\uD589 (\uBC18\uBCF5)
  Orchestrator: \uC2A4\uD504\uB9B0\uD2B8 N \uBC94\uC704 \uC815\uC758
  Generator: \uAD6C\uD604
  Evaluator: \uB3C5\uB9BD \uAC80\uC99D
  [PASS] \u2192 \uB2E4\uC74C \uC2A4\uD504\uB9B0\uD2B8
  [FAIL] \u2192 Generator \uC7AC\uAD6C\uD604 \u2192 \uC7AC\uAC80\uC99D

Phase 3: \uD1B5\uD569
  Integrator: \uC804\uCCB4 \uD1B5\uD569 + \uD68C\uADC0 \uD14C\uC2A4\uD2B8
  Evaluator: \uCD5C\uC885 \uB3C5\uB9BD \uAC80\uC99D
  Orchestrator: \uCEE4\uBC0B \uAC8C\uC774\uD2B8 \uD1B5\uACFC \uD655\uC778
\`\`\`

### \uC2A4\uD504\uB9B0\uD2B8 \uACC4\uC57D (\uC0AC\uC804 \uC815\uC758 \uD544\uC218)
\uAC01 \uC2A4\uD504\uB9B0\uD2B8 \uC2DC\uC791 \uC804 \uB2E4\uC74C\uC744 \uBA85\uC2DC:
- \uC644\uB8CC \uC870\uAC74 (Definition of Done)
- \uC2A4\uCF54\uD504 (\uC218\uC815 \uD30C\uC77C \uBAA9\uB85D)
- \uAC8C\uC774\uD2B8 \uAE30\uC900 (\uD1B5\uACFC/\uC2E4\uD328 \uD310\uC815 \uBC29\uC2DD)

### \uACE0\uC704\uD5D8 \uC601\uC5ED \uCD94\uAC00 \uAC8C\uC774\uD2B8
\uC778\uC99D/DB/\uACB0\uC81C\uAC00 \uD3EC\uD568\uB41C \uACBD\uC6B0:
- [ ] \uBCF4\uC548 \uAC80\uD1A0 (Evaluator \uBCC4\uB3C4 \uC2E4\uD589)
- [ ] \uB864\uBC31 \uACC4\uD68D \uC218\uB9BD
- [ ] \uD504\uB85C\uB355\uC158 \uBC18\uC601 \uC804 \uC0AC\uC6A9\uC790 \uCD5C\uC885 \uD655\uC778

### Architect \uD504\uB86C\uD504\uD2B8 \uD15C\uD50C\uB9BF
\`\`\`
\uB2F9\uC2E0\uC740 \uC18C\uD504\uD2B8\uC6E8\uC5B4 \uC544\uD0A4\uD14D\uD2B8\uC785\uB2C8\uB2E4.

\uD0DC\uC2A4\uD06C: ${task}

\uB2E4\uC74C\uC744 \uD3EC\uD568\uD55C Design \uBB38\uC11C\uB97C \uC791\uC131\uD558\uC138\uC694:
1. \uCEF4\uD3EC\uB10C\uD2B8 \uBD84\uD574 (MECE)
2. \uC778\uD130\uD398\uC774\uC2A4 \uC815\uC758
3. \uB370\uC774\uD130 \uD750\uB984
4. \uD2B8\uB808\uC774\uB4DC\uC624\uD504 (\uC120\uD0DD\uD55C \uC124\uACC4 vs \uB300\uC548)
5. \uB9AC\uC2A4\uD06C\uC640 \uC644\uD654 \uC804\uB7B5
6. \uC2A4\uD504\uB9B0\uD2B8 \uBD84\uD560 \uC81C\uC548 (\uAC01 \uC2A4\uD504\uB9B0\uD2B8 \uC644\uB8CC \uC870\uAC74 \uD3EC\uD568)
\`\`\`
`
  };
  return guides[complexity];
}
function registerOrchestrate(server2) {
  server2.registerTool(
    "orchestrate",
    {
      title: "\uC624\uCF00\uC2A4\uD2B8\uB808\uC774\uC158 \uAC00\uC774\uB4DC \uBC18\uD658",
      description: "\uD0DC\uC2A4\uD06C\uC640 \uBCF5\uC7A1\uB3C4\uC5D0 \uB530\uB978 \uC5D0\uC774\uC804\uD2B8 \uD3B8\uC131 \uAC00\uC774\uB4DC\uC640 \uD504\uB86C\uD504\uD2B8 \uD15C\uD50C\uB9BF\uC744 \uBC18\uD658\uD569\uB2C8\uB2E4.",
      inputSchema: z4.object({
        task: z4.string().describe("\uC218\uD589\uD560 \uD0DC\uC2A4\uD06C \uC124\uBA85"),
        complexity: z4.enum(["simple", "medium", "complex"]).optional().describe(
          "\uBCF5\uC7A1\uB3C4: simple(1~2\uD30C\uC77C), medium(3~7\uD30C\uC77C), complex(8+\uD30C\uC77C/\uC678\uBD80\uC758\uC874\uC131). \uBBF8\uC9C0\uC815 \uC2DC medium"
        )
      })
    },
    async ({ task, complexity }) => {
      const level = complexity ?? "medium";
      const guide = buildOrchestrationGuide(task, level);
      return {
        content: [{ type: "text", text: guide }]
      };
    }
  );
}

// src/tools/verify.ts
import { z as z5 } from "zod";
function buildVerifyChecklist(scope) {
  const base = `## \uACF5\uD1B5 \uAC8C\uC774\uD2B8 (\uBAA8\uB4E0 \uC2A4\uCF54\uD504 \uD544\uC218)

- [ ] tsc / lint \uC5D0\uB7EC \uC5C6\uC74C
- [ ] \uAE30\uB2A5\uC774 \uC694\uAD6C\uC0AC\uD56D\uB300\uB85C \uB3D9\uC791\uD568
- [ ] \uACBD\uACC4\uAC12(0, \uC74C\uC218, \uBE48 \uAC12, \uBE48 \uBC30\uC5F4)\uC5D0\uC11C \uD06C\uB798\uC2DC \uC5C6\uC74C
- [ ] \uAE30\uC874 \uB3D9\uC791 \uD68C\uADC0 \uC5C6\uC74C`;
  const standard = `

## \uD45C\uC900 \uAC80\uC99D (standard + full)

### \uCF54\uB4DC \uD488\uC9C8
- [ ] \uBD88\uD544\uC694\uD55C \uCD94\uC0C1\uD654, \uBBF8\uB798 \uB300\uBE44 \uCF54\uB4DC \uC5C6\uC74C
- [ ] \uC758\uB3C4\uAC00 \uCF54\uB4DC\uC5D0\uC11C \uC9C1\uC811 \uC77D\uD798 (\uAC00\uB3C5\uC131)
- [ ] \uCD5C\uC18C \uBCC0\uACBD \uC6D0\uCE59 \uC900\uC218 (\uBAA9\uD45C \uC678 \uC218\uC815 \uC5C6\uC74C)
- [ ] \uC5D0\uB7EC \uD578\uB4E4\uB9C1\uC774 \uC801\uC808\uD568 (throw vs \uBA54\uC2DC\uC9C0 \uBC18\uD658)

### \uD14C\uC2A4\uD2B8 \uC6A9\uC774\uC131
- [ ] \uBCC0\uACBD \uC0AC\uD56D\uC744 \uAC80\uC99D\uD558\uB294 \uD14C\uC2A4\uD2B8\uAC00 \uC874\uC7AC\uD558\uAC70\uB098 \uCD94\uAC00\uB428
- [ ] \uD14C\uC2A4\uD2B8\uAC00 \uC5C6\uB294 \uACBD\uC6B0, \uC774\uC720\uAC00 \uC815\uB2F9\uD654\uB428

### \uBCF4\uC548 \uAE30\uBCF8
- [ ] \uC0AC\uC6A9\uC790 \uC785\uB825 \uC720\uD6A8\uC131 \uAC80\uC99D \uC874\uC7AC
- [ ] \uBBFC\uAC10 \uC815\uBCF4(\uD0A4, \uD1A0\uD070) \uD558\uB4DC\uCF54\uB529 \uC5C6\uC74C
- [ ] \uD30C\uC77C \uACBD\uB85C \uC870\uC791(path traversal) \uCDE8\uC57D\uC810 \uC5C6\uC74C`;
  const full = `

## \uC2EC\uCE35 \uAC80\uC99D (full \uC804\uC6A9)

### \uC131\uB2A5
- [ ] N+1 \uCFFC\uB9AC \uB610\uB294 \uB8E8\uD504 \uB0B4 I/O \uC5C6\uC74C
- [ ] \uB300\uC6A9\uB7C9 \uB370\uC774\uD130 \uCC98\uB9AC \uC2DC \uBA54\uBAA8\uB9AC \uB204\uC218 \uC5C6\uC74C
- [ ] \uC751\uB2F5 \uC2DC\uAC04\uC774 \uD5C8\uC6A9 \uAE30\uC900 \uC774\uB0B4

### \uACE0\uC704\uD5D8 \uC601\uC5ED (\uC778\uC99D/DB/\uACB0\uC81C)
- [ ] \uC778\uC99D \uC6B0\uD68C \uACBD\uB85C \uC5C6\uC74C
- [ ] SQL \uC778\uC81D\uC158 / NoSQL \uC778\uC81D\uC158 \uBC29\uC5B4
- [ ] \uD2B8\uB79C\uC7AD\uC158 \uC6D0\uC790\uC131 \uBCF4\uC7A5
- [ ] \uACB0\uC81C \uAE08\uC561 \uC815\uD569\uC131 \uAC80\uC99D

### \uC544\uD0A4\uD14D\uCC98
- [ ] \uC124\uACC4 \uBB38\uC11C(Plan/Design)\uC640 \uAD6C\uD604 \uC77C\uCE58
- [ ] \uC778\uD130\uD398\uC774\uC2A4 \uACC4\uC57D \uC900\uC218
- [ ] \uC758\uC874\uC131 \uBC29\uD5A5\uC774 \uC62C\uBC14\uB984 (\uC21C\uD658 \uC758\uC874 \uC5C6\uC74C)
- [ ] \uBC30\uD3EC \uD658\uACBD \uC804\uD658 \uC870\uAC74 \uCDA9\uC871

### \uD1B5\uD569
- [ ] \uC678\uBD80 API \uC5F0\uB3D9 \uC2E4\uD328 \uC2DC \uD3F4\uBC31 \uC874\uC7AC
- [ ] \uD658\uACBD \uBCC0\uC218 \uB204\uB77D \uC2DC \uBA85\uD655\uD55C \uC5D0\uB7EC \uBA54\uC2DC\uC9C0
- [ ] \uB864\uBC31 \uACC4\uD68D \uC218\uB9BD\uB428`;
  const scopes = {
    lite: `# Nova \uAC80\uC99D \uCCB4\uD06C\uB9AC\uC2A4\uD2B8 \u2014 Lite (--fast)

${base}

---

**\uD310\uC815**: PASS / FAIL
**\uC774\uC720**: (\uC2E4\uD328 \uC2DC \uAD6C\uCCB4\uC801 \uD30C\uC77C:\uB77C\uC778 \uBA85\uC2DC)
`,
    standard: `# Nova \uAC80\uC99D \uCCB4\uD06C\uB9AC\uC2A4\uD2B8 \u2014 Standard

${base}
${standard}

---

**\uD310\uC815**: PASS / NEEDS WORK / FAIL
**\uC774\uC288 \uBAA9\uB85D**: (NEEDS WORK/FAIL \uC2DC \uC2EC\uAC01\uB3C4 + \uD30C\uC77C:\uB77C\uC778 + \uB0B4\uC6A9 + \uC81C\uC548)
`,
    full: `# Nova \uAC80\uC99D \uCCB4\uD06C\uB9AC\uC2A4\uD2B8 \u2014 Full (--strict)

${base}
${standard}
${full}

---

**\uD310\uC815**: PASS / NEEDS WORK / FAIL
**\uC774\uC288 \uBAA9\uB85D**: (\uC2EC\uAC01\uB3C4: Critical / High / Medium / Low)

| # | \uC2EC\uAC01\uB3C4 | \uD30C\uC77C:\uB77C\uC778 | \uB0B4\uC6A9 | \uC81C\uC548 |
|---|--------|-----------|------|------|

**\uC798\uB41C \uC810**:
- (\uAD6C\uCCB4\uC801\uC73C\uB85C)
`
  };
  return scopes[scope];
}
function registerVerify(server2) {
  server2.registerTool(
    "verify",
    {
      title: "\uAC80\uC99D \uAE30\uC900 \uCCB4\uD06C\uB9AC\uC2A4\uD2B8 \uBC18\uD658",
      description: "\uAC80\uC99D \uAC15\uB3C4(lite/standard/full)\uC5D0 \uB530\uB978 Nova \uD488\uC9C8 \uAC80\uC99D \uCCB4\uD06C\uB9AC\uC2A4\uD2B8\uB97C \uBC18\uD658\uD569\uB2C8\uB2E4.",
      inputSchema: z5.object({
        scope: z5.enum(["lite", "standard", "full"]).optional().describe(
          "\uAC80\uC99D \uAC15\uB3C4: lite(\uBE60\uB978 \uAC8C\uC774\uD2B8), standard(\uAE30\uBCF8), full(\uC2EC\uCE35/--strict). \uBBF8\uC9C0\uC815 \uC2DC standard"
        )
      })
    },
    async ({ scope }) => {
      const level = scope ?? "standard";
      const checklist = buildVerifyChecklist(level);
      return {
        content: [{ type: "text", text: checklist }]
      };
    }
  );
}

// src/index.ts
var __dirname = path4.dirname(fileURLToPath(import.meta.url));
var NOVA_ROOT = path4.resolve(__dirname, "../..");
var server = new McpServer({
  name: "nova",
  version: "3.12.0"
});
registerGetRules(server, NOVA_ROOT);
registerGetCommands(server, NOVA_ROOT);
registerGetState(server);
registerCreatePlan(server);
registerOrchestrate(server);
registerVerify(server);
var transport = new StdioServerTransport();
await server.connect(transport);
