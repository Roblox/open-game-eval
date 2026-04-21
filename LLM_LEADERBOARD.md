## LLM Leaderboard on Roblox Studio Assistant

<table>
<thead>
    <tr>
        <th rowspan="2">Model</th>
        <th colspan="4" class="eval-pass">Pass Rate</th>
        <th colspan="1" class="response-behavior">Tool Calling</th>
        <th colspan="1" class="eval-debug">Debug Evals</th>
    </tr>
    <tr>
        <th class="eval-pass"><strong>Pass@1</strong></th>
        <th class="eval-pass"><strong>Pass@5</strong></th>
        <th class="eval-pass"><strong>Cons@5</strong></th>
        <th class="eval-pass"><strong>All@5</strong></th>
        <th class="response-behavior"><strong>Avg Tool Error Rate</strong></th>
        <th class="eval-debug"><strong>Debug Pass@1</strong></th>
    </tr>
</thead>
<tbody>
    <tr>
        <td class="model-name">Gemini 3.1 Pro</td>
        <td><strong>55.32%</strong></td>
        <td><strong>72.34%</strong></td>
        <td>54.67%</td>
        <td><strong>44.66%</strong></td>
        <td>1.33%</td>
        <td><strong>56.67%</strong></td>
    </tr>
    <tr>
        <td class="model-name">Gemini 3 Pro</td>
        <td>48.94%</td>
        <td>59.41%</td>
        <td>49.66%</td>
        <td>37.82%</td>
        <td>3.09%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 2.5 Pro</td>
        <td>38.51%</td>
        <td>53.24%</td>
        <td>38.92%</td>
        <td>24.88%</td>
        <td>5.99%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 3 Flash</td>
        <td>54.68%</td>
        <td>65.73%</td>
        <td><strong>56.99%</strong></td>
        <td>39.98%</td>
        <td>2.17%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 2.5 Flash</td>
        <td>23.40%</td>
        <td>40.43%</td>
        <td>22.12%</td>
        <td>14.15%</td>
        <td>4.00%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">Claude Opus 4.7</td>
        <td>46.38%</td>
        <td>61.34%</td>
        <td>45.44%</td>
        <td>34.87%</td>
        <td>2.24%</td>
        <td>52.67%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Opus 4.6</td>
        <td>51.91%</td>
        <td>64.98%</td>
        <td>52.25%</td>
        <td>39.29%</td>
        <td>1.4%</td>
        <td>50.67%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Sonnet 4.6</td>
        <td>46.38%</td>
        <td>57.45%</td>
        <td>46.46%</td>
        <td>37.09%</td>
        <td>1.27%</td>
        <td>46.00%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Opus 4.5</td>
        <td>44.47%</td>
        <td>56.60%</td>
        <td>43.82%</td>
        <td>35.44%</td>
        <td><strong>0.98%</strong></td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">Claude Sonnet 4.5</td>
        <td>38.51%</td>
        <td>49.76%</td>
        <td>39.87%</td>
        <td>25.81%</td>
        <td>1.03%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">Claude Haiku 4.5</td>
        <td>35.74%</td>
        <td>45.63%</td>
        <td>36.20%</td>
        <td>25.46%</td>
        <td>2.94%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">GPT-5.4 (Reasoning: M)</td>
        <td>35.11%</td>
        <td>55.43%</td>
        <td>35.30%</td>
        <td>16.74%</td>
        <td>1.28%</td>
        <td>50.00%</td>
    </tr>
    <tr>
        <td class="model-name">GPT Codex 5.3</td>
        <td>40.43%</td>
        <td>61.70%</td>
        <td>40.43%</td>
        <td>23.12%</td>
        <td>2.14%</td>
        <td>47.33%</td>
    </tr>
    <tr>
        <td class="model-name">GPT-5.2</td>
        <td>30.64%</td>
        <td>46.08%</td>
        <td>29.52%</td>
        <td>19.69%</td>
        <td>2.33%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">GPT-5.1</td>
        <td>31.06%</td>
        <td>42.55%</td>
        <td>31.67%</td>
        <td>20.88%</td>
        <td>3.48%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">GLM 4.5</td>
        <td>40.43%</td>
        <td>53.19%</td>
        <td>40.43%</td>
        <td>30.31%</td>
        <td>1.84%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">GLM 4.6</td>
        <td>38.51%</td>
        <td>49.58%</td>
        <td>39.76%</td>
        <td>25.73%</td>
        <td>7.82%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">GLM 4.7</td>
        <td>43.83%</td>
        <td>62.41%</td>
        <td>45.79%</td>
        <td>22.91%</td>
        <td>5.2%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">GLM 5</td>
        <td>51.70%</td>
        <td>69.01%</td>
        <td>52.37%</td>
        <td>35.07%</td>
        <td>2.02%</td>
        <td>56.00%</td>
    </tr>
    <tr>
        <td class="model-name">LIMI GLM 4.5</td>
        <td>38.09%</td>
        <td>55.02%</td>
        <td>37.66%</td>
        <td>24.10%</td>
        <td>6.18%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">Kimi K2.5 Thinking</td>
        <td>45.74%</td>
        <td>66.06%</td>
        <td>46.35%</td>
        <td>26.35%</td>
        <td>8.1%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">Kimi K2 Thinking</td>
        <td>33.19%</td>
        <td>48.81%</td>
        <td>33.61%</td>
        <td>18.96%</td>
        <td>2.74%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">Minimax M2</td>
        <td>24.68%</td>
        <td>39.47%</td>
        <td>23.77%</td>
        <td>13.30%</td>
        <td>3.75%</td>
        <td>-</td>
    </tr>
    <tr>
        <td class="model-name">GPT-OSS-120B</td>
        <td>29.79%</td>
        <td>46.81%</td>
        <td>28.48%</td>
        <td>19.39%</td>
        <td>4.72%</td>
        <td>-</td>
    </tr>
</tbody>
</table>

**We are serving the open-source models using vLLM on a dedicated 8-way NVIDIA H200 cluster. <br>
**To ensure responsible and effective use, we advise that you prompt-tune the models and run them behind a robust safety guardrail.
<br>
💡 We see that agentic tasks in practice generate deep, multi-step execution paths, and enhancing the model's performance and subsequent evaluation metrics for these trajectories will be a key area of focus.

## Expanded Eval Set (87 Evals)

The expanded eval set adds 40 new evals covering more complex game mechanics (scripting, physics, multi-instance edits, client-server interactions) to the original 47.
<table>
<thead>
    <tr>
        <th rowspan="2">Model</th>
        <th colspan="4" class="eval-pass">Pass Rate</th>
        <th colspan="1" class="response-behavior">Tool Calling</th>
    </tr>
    <tr>
        <th class="eval-pass"><strong>Pass@1</strong></th>
        <th class="eval-pass"><strong>Pass@5</strong></th>
        <th class="eval-pass"><strong>Cons@5</strong></th>
        <th class="eval-pass"><strong>All@5</strong></th>
        <th class="response-behavior"><strong>Avg Tool Error Rate</strong></th>
    </tr>
</thead>
<tbody>
    <tr>
        <td class="model-name">Claude Opus 4.6</td>
        <td><strong>48.05%</strong></td>
        <td><strong>59.77%</strong></td>
        <td><strong>48.05%</strong></td>
        <td><strong>38.28%</strong></td>
        <td><strong>0.71%</strong></td>
    </tr>
    <tr>
        <td class="model-name">Claude Opus 4.7</td>
        <td>43.45%</td>
        <td>58.62%</td>
        <td>43.45%</td>
        <td>32.18%</td>
        <td>1.33%</td>
    </tr>
</tbody>
</table>

> **Comments**: The Pass@1 gap (-4.6pp) between Opus 4.6 and 4.7 is **not statistically significant** (p=0.24, paired t-test). However, tool usage patterns diverge sharply — Opus 4.7 uses 39% fewer tool calls overall (p<0.001), with the largest drops in exploration tools (`search_game_tree`, `script_grep`, `inspect_instance`). See [Detailed Reviews/Opus 4.7 vs 4.6](Detailed%20Reviews/Opus%204.7%20vs%204.6) for a full comparison.

## Debug Eval Leaderboard

Debug evals test an LLM's ability to identify and fix bugs in existing game scripts. Each eval presents a buggy script and the model must correct the issue.

<table>
<thead>
    <tr>
        <th rowspan="2">Model</th>
        <th colspan="4" class="eval-pass">Pass Rate </th>
        <th colspan="1" class="response-behavior">Tool Calling</th>
    </tr>
    <tr>
        <th class="eval-pass"><strong>Pass@1</strong></th>
        <th class="eval-pass"><strong>Pass@5</strong></th>
        <th class="eval-pass"><strong>Cons@5</strong></th>
        <th class="eval-pass"><strong>All@5</strong></th>
        <th class="response-behavior"><strong>Avg Tool Error Rate</strong></th>
    </tr>
</thead>
<tbody>
    <tr>
        <td class="model-name">GLM 5</td>
        <td>56.00%</td>
        <td><strong>73.33%</strong></td>
        <td><strong>59.87%</strong></td>
        <td>33.98%</td>
        <td>2.39%</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 3.1 Pro</td>
        <td><strong>56.67%</strong></td>
        <td>70.00%</td>
        <td>58.36%</td>
        <td><strong>42.68%</strong></td>
        <td>5.97%</td>
    </tr>
    <tr>
        <td class="model-name">GPT-5.4 (Reasoning: M)</td>
        <td>50.00%</td>
        <td>66.67%</td>
        <td>52.05%</td>
        <td>31.57%</td>
        <td>4.36%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Opus 4.6</td>
        <td>50.67%</td>
        <td>66.67%</td>
        <td>49.52%</td>
        <td>40.85%</td>
        <td><strong>0.96%</strong></td>
    </tr>
    <tr>
        <td class="model-name">GPT Codex 5.3</td>
        <td>47.33%</td>
        <td>70.00%</td>
        <td>47.90%</td>
        <td>27.00%</td>
        <td>3.21%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Sonnet 4.6</td>
        <td>46.00%</td>
        <td>60.00%</td>
        <td>46.47%</td>
        <td>33.87%</td>
        <td>6.47%</td>
    </tr>
</tbody>
</table>

## Metrics Explanation
- Pass@1 -- average probability of success in 1 attempt
- Pass@5 -- average probability of success in at least 1 out of 5 attempts
- Cons@5 -- average probability of success in at least 3 out of 5 attempts
- All@5 -- average probability of success in 5 out of 5 attempts
- Avg Tool Error Rate -- average tool call error rates
- Debug Pass@1 -- average probability of fixing a bug in 1 attempt (30 debug evals)
