import { Socket } from "phoenix";

const socket = new Socket("/socket", { params: { token: window.userToken } });

socket.connect();

const createSocket = (topicId) => {
  const channel = socket.channel(`comments:${topicId}`, {});

  channel
    .join()
    .receive("ok", resp => {
      renderComments(resp.comments);
    })
    .receive("error", resp => {
      console.log("Unable to join", resp)
    });
  channel.on(`comments:${topicId}:new`, (event) => renderComment(event.comment));

  document.querySelector('button').addEventListener('click', () => {
    const content = document.querySelector('textarea').value;
    channel.push('comment:add', { content: content });
  });
};

const renderComments = (comments) => {
  const renderedComments = comments.map(getCommentTemplate);
  document.querySelector('.collection').innerHTML = renderedComments.join('');
};

const renderComment = (comment) => {
  const renderedComment = getCommentTemplate(comment);
  document.querySelector('.collection').innerHTML = renderedComment +
    document.querySelector('.collection').innerHTML;
};

const getCommentTemplate = (comment) => {
  let email = (comment.user && comment.user.email) || 'Anonymous';
  return `
    <li class="collection-item">
      ${comment.content}
      <div class="secondary-content">${email}</div>
    </li>
  `;
};

window.createSocket = createSocket;
