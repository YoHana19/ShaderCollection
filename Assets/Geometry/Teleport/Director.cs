using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Playables;
using DG.Tweening;
using GTeleporter;

public class Director : MonoBehaviour
{
    [SerializeField] bool isExecuteByScript;
    [SerializeField] Modifier emitter;
    [SerializeField] Modifier receiver;

    private PlayableDirector playableDirector;

    private void Awake()
    {
        playableDirector = GetComponent<PlayableDirector>();
        playableDirector.enabled = !isExecuteByScript;
        if (isExecuteByScript)
        {
            Execute();
        }
    }

    private void Execute()
    {
        emitter._offset = -0.85f;
        receiver._offset = 1.78f;
        DOTween.To(() => emitter._offset, num => emitter._offset = num, 1f, 1.83f).SetDelay(0.183f).SetLoops(-1, LoopType.Restart);
        var seq = DOTween.Sequence();
        seq.Append(DOTween.To(() => receiver._offset, num => receiver._offset = num, 0f, 1.15f).SetDelay(0.683f));
        seq.SetLoops(-1, LoopType.Restart);
    }
}
