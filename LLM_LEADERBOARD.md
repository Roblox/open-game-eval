## LLM Leaderboard on Roblox Studio Assistant

The benchmark below is based on the **87-eval expanded set**. New model entries land here.

> The previous 47-eval leaderboard has been deprecated and moved to the 'Deprecated' directory. It is retained for historical reference only.

## Expanded Eval Set (87 Evals)

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
        <td class="model-name">Claude Fable 5</td>
        <td><strong>50.34%</strong></td>
        <td>62.07%</td>
        <td><strong>51.09%</strong></td>
        <td><strong>39.52%</strong></td>
        <td>1.40%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Opus 4.6</td>
        <td>48.05%</td>
        <td>59.77%</td>
        <td>48.05%</td>
        <td>38.28%</td>
        <td><strong>0.71%</strong></td>
    </tr>
    <tr>
        <td class="model-name">Gemini 3.5 Flash</td>
        <td>48.05%</td>
        <td><strong>63.22%</strong></td>
        <td>49.03%</td>
        <td>33.86%</td>
        <td>3.30%</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 3 Flash Preview</td>
        <td>47.82%</td>
        <td>60.92%</td>
        <td>48.84%</td>
        <td>35.12%</td>
        <td>5.51%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Opus 4.7</td>
        <td>43.45%</td>
        <td>58.62%</td>
        <td>43.45%</td>
        <td>32.18%</td>
        <td>1.33%</td>
    </tr>
    <tr>
        <td class="model-name">GPT-5.5 (Reasoning: M)</td>
        <td>40.69%</td>
        <td>56.32%</td>
        <td>40.13%</td>
        <td>30.62%</td>
        <td>0.91%</td>
    </tr>
    <tr>
        <td class="model-name">GPT-5.4 (Reasoning: M)</td>
        <td>40.23%</td>
        <td>55.17%</td>
        <td>40.00%</td>
        <td>29.02%</td>
        <td>1.81%</td>
    </tr>
</tbody>
</table>

> **Comments**: See Detailed Reviews for more in depth comparisons between models.
>
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
        <td class="model-name">Claude Fable 5</td>
        <td><strong>64.67%</strong></td>
        <td><strong>73.33%</strong></td>
        <td><strong>66.09%</strong></td>
        <td><strong>54.66%</strong></td>
        <td>1.01%</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 3.1 Pro</td>
        <td>56.67%</td>
        <td>70.00%</td>
        <td>58.36%</td>
        <td>42.68%</td>
        <td>5.97%</td>
    </tr>
    <tr>
        <td class="model-name">GLM 5</td>
        <td>56.00%</td>
        <td><strong>73.33%</strong></td>
        <td>59.87%</td>
        <td>33.98%</td>
        <td>2.39%</td>
    </tr>
    <tr>
        <td class="model-name">Claude Opus 4.7</td>
        <td>52.67%</td>
        <td>63.33%</td>
        <td>53.14%</td>
        <td>43.57%</td>
        <td>4.26%</td>
    </tr>
    <tr>
        <td class="model-name">GPT-5.4 (Reasoning: M)</td>
        <td>51.33%</td>
        <td>63.33%</td>
        <td>52.08%</td>
        <td>39.70%</td>
        <td>2.98%</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 3 Flash Preview</td>
        <td>51.33%</td>
        <td>63.33%</td>
        <td>51.06%</td>
        <td>43.31%</td>
        <td>4.58%</td>
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
        <td class="model-name">GPT-5.5 (Reasoning: M)</td>
        <td>50.00%</td>
        <td>66.67%</td>
        <td>51.02%</td>
        <td>35.18%</td>
        <td>1.54%</td>
    </tr>
    <tr>
        <td class="model-name">Gemini 3.5 Flash</td>
        <td>49.33%</td>
        <td>70.00%</td>
        <td>48.46%</td>
        <td>36.33%</td>
        <td>3.37%</td>
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
