/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Scene Kit Node
*/
module soba.ssk.node;
import inmath.linalg;
import numem.all;
import soba.ssk.effect;
import soba.ssk.ctx;

enum SSKNodeBlendOp {
    /**
        (Default) Overlay blending operation
    */
    overlay,

    /**
        Destination In blending operation
    */
    destIn,

    /**
        Destination Out blending operation
    */
    destOut,

    /**
        Source In blending operation
    */
    srcIn,

    /**
        Source Out blending operation
    */
    srcOut,

    /**
        Add blending operation
    */
    add
}

/**
    A node in the SSK render graph

    SSKNodes *may* throw exceptions derived from SSKException.
*/
class SSKNode {
@nogc:
private:
    weak_vector!SSKNode children;
    SSKNode parent;

    // Ctx
    SSKContext ctx;

    // Rendering info
    weak_vector!SSKEffect effects;
    SSKNodeBlendOp blendOp;

    // Rendering info
    recti bounds;

protected:

    /**
        Sets the bounds of the node
    */
    void setBounds(recti bounds) {
        this.bounds = bounds;
    }

    /**
        Called when an SSKNode has been reparented.
    */
    void onReparent(SSKNode old, SSKNode new_) { }

    /**
        Gets the context this node was created for
    */
    final
    SSKContext getContext() {
        return ctx;
    }

public:

    /**
        Destructor
    */
    ~this() {
        if (!children.adata) {
            foreach(node; children) {
                nogc_delete(children);
            }

            nogc_delete(children);
        }

        if (!effects.adata) {
            nogc_delete(effects);
        }
    }

    this(SSKContext ctx) {
        this.ctx = ctx;
    }

    /**
        Adds a node as a subnode to this node's render graph.

        The parent of a SSKNode becomes the owner of its child nodes.
    */
    final
    void addChild(SSKNode node) {
        node.setParent(this);
    }

    /**
        Sets this node's parent.

        The parent of a SSKNode becomes the owner of its child nodes.
    */
    final
    void setParent(SSKNode other) {

        // Remove from current parent
        if (parent) {
            foreach(i; 0..parent.children.size) {
                if (parent.children[i] is this) {
                    parent.children.remove(i);
                    break;
                }
            }
        }

        // Allow node to respond to reparenting.
        this.onReparent(parent, other);

        // Update parent
        this.parent = other;
        this.parent.children.pushBack(this);
    }

    /**
        Gets the bounds of the node, pixel aligned.
    */
    recti getBounds() {
        return bounds;
    }

    /**
        Gets the current blending operation applied to this node
    */
    final
    SSKNodeBlendOp getBlendOp() {
        return blendOp;
    }

    /**
        Sets the current blending operation applied to this node
    */
    final
    SSKNodeBlendOp setBlendOp(SSKNodeBlendOp op) {
        this.blendOp = op;
        return blendOp;
    }

    /**
        Pushes an effect to the node's effect stack

        SSKNodes do *not* own effects applied to them, remember to free them after use
    */
    final
    void pushEffect(SSKEffect effect) {
        effects.pushBack(effect);
    }

    /**
        Pops an effect to the node's effect stack

        Returns the effect popped if there was any.

        SSKNodes do *not* own effects applied to them, remember to free them after use
    */
    final
    SSKEffect popEffect() {
        SSKEffect effect;
        if (!effects.empty) {
            effect = effects[$-1];
            effects.popBack();
        }
        return effect;
    }

    /**
        Gets a slice of the current effects applied to this node

        SSKNodes do *not* own effects applied to them, remember to free them after use
    */
    final
    SSKEffect[] getEffects() {
        return effects[0..$];
    }

    /**
        Enqueues a redraw of this node
    */
    final
    void redraw() {
        ctx.enqueue(this);
    }

    /**
        Enqueues a redraw of this node and and all child nodes
    */
    final
    void redrawAll() {
        foreach(child; children) {
            child.redrawAll();
        }
    }
}