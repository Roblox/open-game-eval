## LLM Leaderboard on Roblox Studio Assistant

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
        <td class="model-name">Gemini 3 Pro</td>
        <td>48.94%</td>
        <td>59.41%</td>
        <td>49.66%</td>
        <td>37.82%</td>
        <td>3.09%</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 2.5 Pro</td>
        <td>38.51%</td>
        <td>53.24%</td>
        <td>38.92%</td>
        <td>24.88%</td>
        <td>5.99%</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 3 Flash</td>
        <td><strong>54.68%</strong></td>
        <td><strong>65.73%</strong></td>
        <td><strong>56.99%</strong></td>
        <td><strong>39.98%</strong></td>
        <td>2.17%</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 2.5 Flash</td>
        <td>23.40%</td>
        <td>40.43%</td>
        <td>22.12%</td>
        <td>14.15%</td>
        <td>4.00%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Opus 4.5</td>
        <td>44.47%</td>
        <td>56.60%</td>
        <td>43.82%</td>
        <td>35.44%</td>
        <td><strong>0.98%</strong></td>
    </tr>
    <tr>
        <td class="model-name">Claude Sonnet 4.5</td>
        <td>38.51%</td>
        <td>49.76%</td>
        <td>39.87%</td>
        <td>25.81%</td>
        <td>1.03%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Haiku 4.5</td>
        <td>35.74%</td>
        <td>45.63%</td>
        <td>36.20%</td>
        <td>25.46%</td>
        <td>2.94%</td>
    </tr>
    <tr>
        <td class="model-name">GPT-5.2</td>
        <td>30.64%</td>
        <td>46.08%</td>
        <td>29.52%</td>
        <td>19.69%</td>
        <td>2.33%</td>
    </tr>
    <tr>
        <td class="model-name">GPT-5.1</td>
        <td>31.06%</td>
        <td>42.55%</td>
        <td>31.67%</td>
        <td>20.88%</td>
        <td>3.48%</td>
    </tr>
    <tr>
        <td class="model-name">GLM 4.5</td>
        <td>40.43%</td>
        <td>53.19%</td>
        <td>40.43%</td>
        <td>30.31%</td>
        <td>1.84%</td>
    </tr>
    <tr>
        <td class="model-name">GLM 4.6</td>
        <td>38.51%</td>
        <td>49.58%</td>
        <td>39.76%</td>
        <td>25.73%</td>
        <td>7.82%</td>
    </tr>
    <tr>
        <td class="model-name">GLM 4.7</td>
        <td>43.83%</td>
        <td>62.41%</td>
        <td>45.79%</td>
        <td>22.91%</td>
        <td>5.2%</td>
    </tr>
    <tr>
        <td class="model-name">LIMI GLM 4.5</td>
        <td>38.09%</td>
        <td>55.02%</td>
        <td>37.66%</td>
        <td>24.10%</td>
        <td>6.18%</td>
    </tr>
    </tr><tr>
        <td class="model-name">Kimi K2.5 Thinking</td>
        <td>45.74%</td>
        <td>66.06%</td>
        <td>46.35%</td>
        <td>26.35%</td>
        <td>8.1%</td>
    </tr>
    <tr>
        <td class="model-name">Kimi K2 Thinking</td>
        <td>33.19%</td>
        <td>48.81%</td>
        <td>33.61%</td>
        <td>18.96%</td>
        <td>2.74%</td>
    </tr>
    <tr>
        <td class="model-name">Minimax M2</td>
        <td>24.68%</td>
        <td>39.47%</td>
        <td>23.77%</td>
        <td>13.30%</td>
        <td>3.75%</td>
    </tr>
    <tr>
        <td class="model-name">GPT-OSS-120B</td>
        <td>29.79%</td>
        <td>46.81%</td>
        <td>28.48%</td>
        <td>19.39%</td>
        <td>4.72%</td>
    </tr>
</tbody>
</table>

**We are serving the open-source models using vLLM on a dedicated 8-way NVIDIA H200 cluster. <br>
**To ensure responsible and effective use, we advise that you prompt-tune the models and run them behind a robust safety guardrail.
<br>
💡 We see that agentic tasks in practice generate deep, multi-step execution paths, and enhancing the model's performance and subsequent evaluation metrics for these trajectories will be a key area of focus.

## Metrics Explaination
- Pass@1 -- average probability of success in 1 attempt
- Pass@5 -- average probability of success in at least 1 out of 5 attempts
- Cons@5 -- average probability of success in at least 3 out of 5 attempts
- All@5 -- average probability of success in 5 out of 5 attempts
- Avg Tool Error Rate -- average tool call error rates
