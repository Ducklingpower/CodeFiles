function LiveHoverPlot(L1,L2,W,xo,yo,r,n,sampling_method)
    close all;
    
    hFig = figure('Name', 'Hover-Based Interactive Plot');
    t = tiledlayout(1, 2, 'TileSpacing', 'compact'); 
    ax1 = nexttile(t);
    hold(ax1, 'on');
    plotSampleConfigurationSpaceTwoLink(L1, L2, W, xo, yo, r, sampling_method, n);
    title(ax1, 'Hover to Select Beta & Alpha');
    xlabel(ax1, 'Beta');
    ylabel(ax1, 'Alpha');
    ax2 = nexttile(t);
    hold(ax2, 'on');  
    title(ax2, 'Live Environment Plot');

   
    set(hFig, 'WindowButtonMotionFcn', @(src, event) mouseMove(ax1, ax2, L1, L2, W, xo, yo, r));
end

function mouseMove(ax1, ax2, L1, L2, W, xo, yo, r)
    C = get(ax1, 'CurrentPoint');
    beta = C(1,1);
    alpha = C(1,2);
    assignin('base', 'hover_beta', beta);
    assignin('base', 'hover_alpha', alpha);
    title(ax1, sprintf('Beta: %.2f, Alpha: %.2f', beta, alpha));
    axes(ax2);
    delete(findobj(ax2, 'Type', 'patch'));

    plotEnvironment(L1, L2, W, beta, alpha, xo, yo, r);
    drawnow;
end
