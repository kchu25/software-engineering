@def title = "C2H2 zinc finger as a genome editing tool"
@def published = "20 November 2022"
@def tags = ["comp-bio"]

### C2H2 zinc finger as a genome editing tool


@@img-small ![Zinc-Finger](/blog/pics/zf.png) @@
> [C2H2 zinc finger protein](https://en.wikipedia.org/wiki/Zinc_finger).



At this time of writing, using a Zinc finger (C2H2-ZF) to edit DNA sequences sounds ridiculous.

There are much easier tools to edit DNA sequences, e.g., CRISPR Cas 9.

Like its name, C2H2-ZF proteins use their "fingers" to interact with the DNA. We now have pretty standard technologies to make the fingers of C2H2-ZF, i.e., the fingers are now our lego bricks. The bottleneck is that we don't have a clear picture of how the composition of the fingers of a C2H2-ZF affects its DNA binding sites.

Exhaustively checking the different compositions of C2H2-ZF and their binding sites is not an option since protein engineering is expensive.

#### Recognition code
From a computer science perspective, the above senario is a task of characterizing the following map

$$\fbm : \textsf{amino acid composition of a C2H2-ZF} \rightarrow \textsf{binding sites}$$

where the map $\fbm$ is called the *recognition code* in biology. The recognition code is very much a machine-learning problem. Several established tools exist, such as the [Interactive PWM predictor](http://zf.princeton.edu/logoMain.php) and [RCADE](http://rcade.ccbr.utoronto.ca/Help.html), which seek to characterize the recognition code. Both tools characterize the binding sites as [position weight matrices (PWM)](https://en.wikipedia.org/wiki/Position_weight_matrix).

Whether to characterize the binding sites in the recognition code problem as a PWM is an open research question. PWM is a compact representation of the binding sites and a [local representation](../dist_rep/). It offers easy interpretations but at the same time, making simplifying assumptions –– e.g., an independent contribution from each position to the binding specificity. Some argue that we need a more expressive representation to reveal more biological insights.

#### What's advantageous about C2H2 zinc fingers for genome editing?

C2H2 zinc fingers are smaller than other genome editing tools, giving it a more straightforward delivery process into the cell via viral vectors.

<!-- 
However, it’s possible that after throwing an enormous amount of brain power into solving the recognition code, the result turns out that it's impossible to manipulate the binding sites to the degree we want using C2H2-ZF. It's also possible that some relaxed version of this problem, e.g., to incorporate more information in the domain of $\fbm$ in equation (1), could reveal more biological insights.

Nonetheless, recognition code is an excellent example showing that, given sufficient data, we can use clever modeling techniques and significantly impact biological science. -->

---

Update (4/7/2023):

Recently, an article was published about using ZF as a recognition code. I haven't looked into it in detail; if you are interested, see [A universal deep-learning model for zinc finger design enables transcription factor reprogramming](https://www.nature.com/articles/s41587-022-01624-4).

#### References

{{show_refs gupta2014expanding najafabadi2015identification persikov2009 ichikawa2023universal}}