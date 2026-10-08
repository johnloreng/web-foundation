const loadBtn = document.getElementById('load-users');
const filterInput = document.getElementById('filter-input');
const status = document.getElementById('status');
const usersList = document.getElementById('users-list');

let allUsers = []; // cache fetched users for client-side filtering

async function loadUsers() {
  // Disable button and show loading message
  loadBtn.disabled = true;
  status.textContent = 'Loading…';
  usersList.innerHTML = '';

  try {
    const response = await fetch('https://jsonplaceholder.typicode.com/users');

    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status} ${response.statusText}`);
    }

    allUsers = await response.json();
    status.textContent = `${allUsers.length} users loaded.`;
    renderUsers(allUsers);
  } catch (err) {
    status.textContent = `Error: ${err.message}`;
  } finally {
    loadBtn.disabled = false;
  }
}

function renderUsers(users) {
  usersList.innerHTML = '';

  if (users.length === 0) {
    const li = document.createElement('li');
    li.textContent = 'No users match your filter.';
    usersList.appendChild(li);
    return;
  }

  users.forEach((user) => {
    const li = document.createElement('li');

    const name = document.createElement('strong');
    name.textContent = user.name;

    const email = document.createElement('span');
    email.textContent = ` — ${user.email}`;

    const city = document.createElement('span');
    city.textContent = ` | ${user.address.city}`;

    const company = document.createElement('span');
    company.textContent = ` | ${user.company.name}`;

    li.appendChild(name);
    li.appendChild(email);
    li.appendChild(city);
    li.appendChild(company);
    usersList.appendChild(li);
  });
}

function filterUsers() {
  const query = filterInput.value.toLowerCase();
  const filtered = allUsers.filter((user) =>
    user.name.toLowerCase().includes(query)
  );
  renderUsers(filtered);
}

loadBtn.addEventListener('click', loadUsers);
filterInput.addEventListener('input', filterUsers);
